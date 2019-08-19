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

    var scannedCodes = [String]()
    var devices = [String:Device]() {
        didSet {
            if devices.count == 0 {
                scannedCodes.removeAll()
            }
            updateButtons()
        }
    }
    let qrScannerQueue = DispatchQueue(label: "qrScannerQueue")
    var employee: Employee? = nil
    
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
        if unwindSegue.identifier == "SelectedConnectorUnwindSegue" {
            let source = unwindSegue.source as! ConnectorViewController
            employee = source.employee
            guard employee != nil else { return }
            // TODO confirm checkout
            print("Selected \(employee!.name)")
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
        devices.removeAll()
        employee = nil
        deviceTableView.reloadData()
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

}

// MARK: - TableView

extension ScannerViewController {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return scannedCodes.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "DeviceCell", for: indexPath)
        let deviceId = scannedCodes[indexPath.row]
        guard let device = devices[deviceId] else { return cell }

        cell.textLabel?.text = device.name
        cell.detailTextLabel?.text = device.status.statusMeta == .deployable ? "Checkout" : "Return"

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
    func deviceFrom(deviceId id: String) {
        firstly {
            SnipeManager.getDevice(forId: id)
            }.done { result in
                self.devices[id] = result
                self.deviceTableView.reloadData()
            }.catch { error in
                self.scannedCodes.removeAll(where: { $0 == id })
            }
    }
}
