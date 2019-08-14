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

    var scannedCodes = [String]()
    var devices = [String:Device]()
    let qrScannerQueue = DispatchQueue(label: "qrScannerQueue")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        deviceTableView.delegate = self
        deviceTableView.dataSource = self

        setUpVideoCaptureSession()

        scannerView.layer.borderColor = #colorLiteral(red: 0, green: 0.9768045545, blue: 0, alpha: 1)
        scannerView.layer.borderWidth = 2
        cameraView.bringSubviewToFront(scannerView)
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    
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
    
    func parseDeviceId(fromMessage message: String) -> String? {
        if !isValidQRCode(message) {
            return nil
        }
        return message.replacingOccurrences(of: SnipeManager.urlPrefix, with: "")
    }

    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        // Process only one code at a time
        guard metadataObjects.indices.contains(0),
            let metadataObject = metadataObjects[0] as? AVMetadataMachineReadableCodeObject,
            metadataObject.type == AVMetadataObject.ObjectType.qr,
            let message = metadataObject.stringValue else { return }

        didScan(QRCode: message)
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
