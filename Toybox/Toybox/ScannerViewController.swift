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

class ScannerViewController: UIViewController,
AVCaptureMetadataOutputObjectsDelegate,
UITableViewDataSource,
UITableViewDelegate {

    @IBOutlet var cameraView: UIView!
    @IBOutlet var scannerView: UIView!
    @IBOutlet var deviceTableView: UITableView!
    @IBOutlet var confirmButton: UIButton!
    @IBOutlet var cancelButton: UIButton!
    @IBOutlet var continueButton: UIButton!
    @IBOutlet var checkoutActivityIndicator: UIActivityIndicatorView!
    @IBOutlet var scanTabBarItem: UITabBarItem!

    var scannedCodes = [String]()
    var devices = [Device]() {
        didSet {
            if devices.count == 0 {
                scannedCodes.removeAll()
            }
            deviceTableView.reloadData()
            updateButtons()
        }
    }
    var employee: Employee? = nil {
        didSet {
            updateButtons()
        }
    }

    let qrScannerQueue = DispatchQueue(label: "qrScannerQueue")
    let videoCaptureSession: AVCaptureSession = AVCaptureSession()
    let captureMetadataOutput = AVCaptureMetadataOutput()
    var videoPreviewLayer: AVCaptureVideoPreviewLayer? = nil

    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        deviceTableView.delegate = self
        deviceTableView.dataSource = self

        updateButtons()
        setUpVideoCaptureSession()
        scannerView.layer.borderColor = #colorLiteral(red: 0, green: 0.9768045545, blue: 0, alpha: 1)
        scannerView.layer.borderWidth = 2


        if let qrCodeImage = createQRCodeImage(from: "https://connected.io") {
            scanTabBarItem.image = UIImage(ciImage: qrCodeImage).withRenderingMode(.alwaysOriginal)
            scanTabBarItem.selectedImage = UIImage(ciImage: qrCodeImage).withRenderingMode(.alwaysOriginal)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        videoCaptureSession.startRunning()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        videoCaptureSession.stopRunning()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        cameraView.bringSubviewToFront(scannerView)
        if let videoPreviewLayer = videoPreviewLayer {
            videoPreviewLayer.videoGravity = .resizeAspectFill
            videoPreviewLayer.frame.size = cameraView.frame.size
            captureMetadataOutput.rectOfInterest = videoPreviewLayer.metadataOutputRectConverted(fromLayerRect: scannerView.frame)
        }
    }

    func createQRCodeImage(from string: String) -> CIImage? {
        let data = string.data(using: String.Encoding.ascii)
        guard let qrFilter = CIFilter(name: "CIQRCodeGenerator") else { return nil }
        qrFilter.setValue(data, forKey: "inputMessage")
        return qrFilter.outputImage
    }

    // MARK: - Navigation
    
    @IBAction func unwindToScanner(_ unwindSegue: UIStoryboardSegue) {
        guard unwindSegue.identifier == "SelectedConnectorUnwindSegue",
            let source = unwindSegue.source as? ConnectorViewController else { return }
        employee = source.employee
        deviceTableView.reloadData()
    }
    
    // MARK: - AV

    func setUpVideoCaptureSession() {
        if videoCaptureSession.inputs.count > 0
            && videoCaptureSession.outputs.count > 0 {
                return
        }

        guard let captureDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
            let input = try? AVCaptureDeviceInput(device: captureDevice)
            else {
                // TODO handle error
                print("Failed to get the camera device")
                return
            }

        videoPreviewLayer = AVCaptureVideoPreviewLayer(session: videoCaptureSession)

        videoCaptureSession.beginConfiguration()
        videoCaptureSession.addInput(input)
        videoCaptureSession.addOutput(captureMetadataOutput)
        videoCaptureSession.commitConfiguration()

        captureMetadataOutput.setMetadataObjectsDelegate(self, queue: qrScannerQueue)
        captureMetadataOutput.metadataObjectTypes = [AVMetadataObject.ObjectType.qr]

        cameraView.layer.addSublayer(videoPreviewLayer!)
    }

    // MARK: - Actions

    @IBAction func cancelAction(_ sender: Any) {
        reset()
    }

    @IBAction func continueAction(_ sender: Any) {
        if employee != nil {
            checkout()
            return
        }

        let alertController = UIAlertController(title: "Transfer or Return?", message: "If you would like to transfer these devices, click transfer and choose the employee receiving the devices...", preferredStyle: .actionSheet)
        let transferAction = UIAlertAction(title: "Transfer", style: .default, handler: { (alert: UIAlertAction!) -> Void in
            self.performSegue(withIdentifier: "SelectConnectorSegue", sender: self)
        })
        let returnAction = UIAlertAction(title: "Return", style: .destructive, handler: { (alert: UIAlertAction!) -> Void in
            self.checkout()
        })
        alertController.addAction(transferAction)
        alertController.addAction(returnAction)
        alertController.popoverPresentationController?.permittedArrowDirections = [.down]
        alertController.popoverPresentationController?.sourceView = confirmButton
        alertController.popoverPresentationController?.sourceRect = CGRect(x: confirmButton.bounds.midX, y: 0, width: 0, height: 0)

        if devicesByCheckout(.checkout).count > 0 {
            self.performSegue(withIdentifier: "SelectConnectorSegue", sender: self)
        } else if devicesByCheckout(.checkin).count > 0 {
            self.present(alertController, animated: false, completion: nil)
        }
    }

    // MARK: - Utility functions

    func devicesByCheckout(_ type: CheckoutType) -> [Device] {
        return devices.filter { checkoutType(for: $0, and: employee) == type }
    }

    func updateButtons() {
        let isEnabled = devices.count > 0 ? true : false
        confirmButton.isEnabled = isEnabled
        cancelButton.isEnabled = isEnabled

        let alpha = CGFloat(isEnabled ? 1.0 : 0.5)
        confirmButton.alpha = alpha
        cancelButton.alpha = alpha

        if devices.count > 0 && devicesByCheckout(.checkin).count == devices.count {
            continueButton.setTitle("Return", for: .normal)
        } else if employee == nil {
            continueButton.setTitle("Continue", for: .normal)
        } else {
            continueButton.setTitle("Check Out", for: .normal)
        }

    }

    func reset() {
        employee = nil
        devices.removeAll()
    }

    func checkoutType(for device: Device, and employee: Employee? = nil) -> CheckoutType {
        let status = device.status.statusMeta
        switch status {
        case .deployable:
            return .checkout
        case .deployed:
            if let employee = employee,
                let assignee = device.assignee {
                return employee != assignee ? .transfer : .checkin
            }
            return .checkin
        default:
            break
        }
        return .unavailable
    }
}

// MARK: - TableView

extension ScannerViewController {
    func sections() -> Set<CheckoutType> {
        return devices.reduce(into: Set<CheckoutType>()) { statusSet, device in
            statusSet.insert(checkoutType(for: device, and: employee))
        }
    }

    func devicesInSection(section: Int) -> [Device] {
        let sortedSections = Array(sections()).sorted()
        return devices.filter{ checkoutType(for: $0, and: employee) == sortedSections[section] }
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return sections().count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return devicesInSection(section: section).count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let sortedSections = Array(sections()).sorted()
        return sortedSections[section].string
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "DeviceCell", for: indexPath)

        let devicesSubset = devicesInSection(section: indexPath.section)
        cell.textLabel?.text = devicesSubset[indexPath.row].name

        if let employee = employee,
            (indexPath.section, indexPath.row) == (0, 0) {
            cell.textLabel?.text?.append(contentsOf: " (as \(employee.name))")
        }

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

        DispatchQueue.main.async(qos: .userInteractive) {
            UIView.animateKeyframes(withDuration: 0.5, delay: 0, options: [], animations: {
                self.cameraView.alpha = 0.25
                self.cameraView.alpha = 1.0
            }, completion: nil)
        }

        scannedCodes.append(deviceId)
        self.deviceFrom(deviceId: deviceId)
    }
}

// MARK: - Devices

extension ScannerViewController {
    func deviceFrom(deviceId id: String) {
        firstly {
            SnipeManager.getDevice(forId: id)
            }.done { device in
                self.devices.append(device)
            }.catch { error in
                // TODO: This will cause barcodes to be scanned continuously
                self.scannedCodes.removeAll(where: { $0 == id })
            }
    }

    func checkout(onComplete: (() -> ())? = nil) {
        view.bringSubviewToFront(checkoutActivityIndicator)
        checkoutActivityIndicator.isHidden = false
        checkoutActivityIndicator.startAnimating()

        var allPromises = [Promise<String>]()
        if let employee = employee {
            allPromises.append(contentsOf: devices.filter { checkoutType(for: $0) == .checkout }.map {
                SnipeManager.borrowDevice(withId: "\($0.identifier)", toEmployee: "\(employee.id)")
            })
            allPromises.append(contentsOf: devices.filter { checkoutType(for: $0, and: employee) == .transfer }.map { device in
                SnipeManager.returnDevice(device: device).then({ _ in
                    SnipeManager.borrowDevice(withId: "\(self.devices[0].identifier)", toEmployee: "\(employee.id)")
                })
            })
        }
        allPromises.append(contentsOf: devices.filter { checkoutType(for: $0) == .checkin }.map {
            SnipeManager.returnDevice(device: $0)
        })

        when(resolved: allPromises).done { results in
            // TODO: Display some kind of confirmation to user
            if let onComplete = onComplete {
                onComplete()
            }

            self.checkoutActivityIndicator.stopAnimating()
            self.reset()
        }
    }
}
