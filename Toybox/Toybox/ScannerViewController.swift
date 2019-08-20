//
//  ScannerViewController.swift
//  Toybox
//
//  Created by cl-dev on 2019-08-12.
//  Copyright © 2019 AppCoda. All rights reserved.
//

import AVFoundation
import PromiseKit
import UIKit

enum CheckoutType: Int, Comparable {
    case checkout
    case checkin
    case transfer
    case unavailable

    static let typeMap: [CheckoutType: String] = [
        .checkout: "Borrow",
        .checkin: "Return",
        .transfer: "Transfer",
        .unavailable: "Unavailable"
    ]

    var string: String {
        return CheckoutType.typeMap[self]!
    }

    static func <(lhs: CheckoutType, rhs: CheckoutType) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}

class ScannerViewController: UIViewController,
AVCaptureMetadataOutputObjectsDelegate,
UITableViewDataSource,
UITableViewDelegate {

    @IBOutlet var cameraView: UIView!
    @IBOutlet var scannerView: UIView!
    @IBOutlet var deviceTableView: UITableView!
    @IBOutlet var confirmButton: UIButton!
    @IBOutlet var cancelButton: UIButton!
    @IBOutlet var checkoutActivityIndicator: UIActivityIndicatorView!

    var scannedCodes = [String]()
    var devices = [CheckoutType:[Device]]() {
        didSet {
            if devices.count == 0 {
                scannedCodes.removeAll()
            }
            updateButtons()
        }
    }
    let qrScannerQueue = DispatchQueue(label: "qrScannerQueue")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        deviceTableView.delegate = self
        deviceTableView.dataSource = self

        updateButtons()
        setUpVideoCaptureSession()

        scannerView.layer.borderColor = #colorLiteral(red: 0, green: 0.9768045545, blue: 0, alpha: 1)
        scannerView.layer.borderWidth = 2
        cameraView.bringSubviewToFront(scannerView)
    }
    

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {}

    @IBAction func unwindToScanner(_ unwindSegue: UIStoryboardSegue) {
        guard unwindSegue.identifier == "SelectedConnectorUnwindSegue",
            let source = unwindSegue.source as? ConnectorViewController,
            let employee = source.employee,
            let segue = unwindSegue as? UIStoryboardSegueWithCompletion else { return }

        segue.completion = {
            let alertController = UIAlertController(title: "Confirm Transaction", message: "Do you wish to complete transaction as \(employee.name)?", preferredStyle: .actionSheet)
            let noAction = UIAlertAction(title: "No", style: .cancel, handler: nil)
            let yesAction = UIAlertAction(title: "Yes", style: .default, handler: { _ in
                self.checkout(as: employee, onComplete: {})
            })

            alertController.addAction(noAction)
            alertController.addAction(yesAction)
            alertController.popoverPresentationController?.sourceView = self.view
            self.present(alertController, animated: true, completion: nil)
        }
    }
    
    // MARK: - AV

    func setUpVideoCaptureSession() {
        guard let captureDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
            let input = try? AVCaptureDeviceInput(device: captureDevice)
            else {
                print("Failed to get the camera device")
                return
            }
        
        let videoCaptureSession = AVCaptureSession()
        let captureMetadataOutput = AVCaptureMetadataOutput()
        let videoPreviewLayer = AVCaptureVideoPreviewLayer(session: videoCaptureSession)

        videoCaptureSession.beginConfiguration()
        videoCaptureSession.addInput(input)
        videoCaptureSession.addOutput(captureMetadataOutput)
        videoCaptureSession.commitConfiguration()

        captureMetadataOutput.setMetadataObjectsDelegate(self, queue: qrScannerQueue)
        captureMetadataOutput.metadataObjectTypes = [AVMetadataObject.ObjectType.qr]

        videoPreviewLayer.videoGravity = .resizeAspectFill
        videoPreviewLayer.frame = cameraView.bounds
        cameraView.layer.addSublayer(videoPreviewLayer)

        videoCaptureSession.startRunning()
        
        // For reasons unknown, in order to work as expected this must appear after startRunning().
        captureMetadataOutput.rectOfInterest = videoPreviewLayer.metadataOutputRectConverted(fromLayerRect: scannerView.frame)
    }

    // MARK: - Actions

    @IBAction func cancelAction(_ sender: Any) {
        reset()
    }

    // MARK: - Utility functions

    func updateButtons() {
        let isEnabled = devices.count > 0 ? true : false
        confirmButton.isEnabled = isEnabled
        cancelButton.isEnabled = isEnabled

        let alpha = CGFloat(isEnabled ? 1.0 : 0.5)
        confirmButton.alpha = alpha
        cancelButton.alpha = alpha
    }

    func reset() {
        devices.removeAll()
        deviceTableView.reloadData()
    }

    func checkoutType(for device: Device) -> CheckoutType {
        let status = device.status.statusMeta
        switch status {
        case .deployable:
            return .checkout
        case .deployed:
            return .checkin
        default:
            break
        }
        return .unavailable
    }
}

// MARK: - TableView

extension ScannerViewController {
    func numberOfSections(in tableView: UITableView) -> Int {
        return devices.keys.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sections = devices.keys.sorted()
        let devicesSection = sections[section]
        return devices[devicesSection]?.count ?? 0
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let sections = devices.keys.sorted()
        return sections[section].string
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "DeviceCell", for: indexPath)

        let sections = devices.keys.sorted()
        let devicesSection = sections[indexPath.section]
        // XXX: Force unwrap here, instead?
        guard let device = devices[devicesSection]?[indexPath.row] else { return cell }

        cell.textLabel?.text = device.name

        return cell
    }
}

// MARK: - QR Code

extension ScannerViewController {
    func isValidQRCode(_ message: String) -> Bool {
        return message.hasPrefix(SnipeManager.urlPrefix)
    }
    
    func parseDeviceId(fromQRCode code: String) -> String? {
        if !isValidQRCode(code) {
            return nil
        }
        return code.replacingOccurrences(of: SnipeManager.urlPrefix, with: "")
    }

    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        // Process only one code at a time
        guard metadataObjects.indices.contains(0),
            let metadataObject = metadataObjects[0] as? AVMetadataMachineReadableCodeObject,
            metadataObject.type == AVMetadataObject.ObjectType.qr,
            let qrCode = metadataObject.stringValue else { return }

        didScan(QRCode: qrCode)
    }

    func didScan(QRCode code: String) {
        guard let deviceId = parseDeviceId(fromQRCode: code),
            !scannedCodes.contains(deviceId) else { return }

        print("New device Scanned: \(deviceId)")
        scannedCodes.append(deviceId)
        self.deviceFrom(deviceId: deviceId)
    }
}

// MARK: - Devices

extension ScannerViewController {
    func add(device: Device) {
        let deviceCheckoutType = checkoutType(for: device)
        devices[deviceCheckoutType] = devices[deviceCheckoutType] ?? []
        devices[deviceCheckoutType]!.append(device)
    }

    func deviceFrom(deviceId id: String) {
        firstly {
            SnipeManager.getDevice(forId: id)
            }.done { device in
                self.add(device: device)
                self.deviceTableView.reloadData()
            }.catch { error in
                self.scannedCodes.removeAll(where: { $0 == id })
            }
    }

    func checkout(as employee: Employee, onComplete: @escaping () -> Void) {
        view.bringSubviewToFront(checkoutActivityIndicator)
        checkoutActivityIndicator.isHidden = false
        checkoutActivityIndicator.startAnimating()

        let checkoutPromises = devices[.checkout]?.map { device in
            SnipeManager.borrowDevice(withId: "\(device.identifier)", toEmployee: "\(employee.id)")
        } ?? []

        let checkinPromises = devices[.checkin]?.map { device in
            SnipeManager.returnDevice(device: device)
        } ?? []

        let allPromises = checkoutPromises + checkinPromises

        when(resolved: allPromises).done { results in
            // TODO: Display some kind of confirmation to user
            let countFulfilled = results.filter { $0.isFulfilled }.count
            print("\(countFulfilled) successful requests")
            onComplete()
            self.checkoutActivityIndicator.stopAnimating()
            self.reset()
        }
    }
}
