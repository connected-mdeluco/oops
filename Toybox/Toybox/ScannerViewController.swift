//
//  ScannerViewController.swift
//  Toybox
//
//  Created by cl-dev on 2019-08-12.
//  Copyright © 2019 AppCoda. All rights reserved.
//

import AVFoundation
import UIKit

class ScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet var cameraView: UIView!
    @IBOutlet var scannerView: UIView!
    
    var deviceIds = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

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
        videoCaptureSession.addInput(input)

        let captureMetadataOutput = AVCaptureMetadataOutput()
        videoCaptureSession.addOutput(captureMetadataOutput)

        captureMetadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
        captureMetadataOutput.metadataObjectTypes = [AVMetadataObject.ObjectType.qr]

        let videoPreviewLayer = AVCaptureVideoPreviewLayer(session: videoCaptureSession)
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
        return 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: DeviceTableViewCell.identifier, for: indexPath)
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
            let message = metadataObject.stringValue,
            let deviceId = parseDeviceId(fromMessage: message) else { return }

        // TODO: Use deviceId
        print("QR Code Found: \(deviceId)")
    }
}
