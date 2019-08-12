//
//  ScannerViewController.swift
//  Toybox
//
//  Created by cl-dev on 2019-08-12.
//  Copyright © 2019 AppCoda. All rights reserved.
//

import AVFoundation
import UIKit

class ScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    @IBOutlet var scannerView: UIView!
    
    private var employee: Employee?
    private var deviceIds = [String]()
    
    var devices = [String: Device]()
    var videoCaptureSession: AVCaptureSession?
    var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    var qrCodeFrameView: UIView?
    var player: AVAudioPlayer?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setUpVideoCaptureSession()
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    
    func setUpVideoCaptureSession() {
        let deviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera],
                                                                      mediaType: AVMediaType.video,
                                                                      position: .front)
        
        guard let captureDevice = deviceDiscoverySession.devices.first else {
            print("Failed to get the camera device")
            return
        }
        
        do {
            // Get an instance of the AVCaptureDeviceInput class using the previous device object.
            let input = try AVCaptureDeviceInput(device: captureDevice)
            
            videoCaptureSession = AVCaptureSession()
            
            // Set the input device on the capture session.
            videoCaptureSession?.addInput(input)
            
            let captureMetadataOutput = AVCaptureMetadataOutput()
            videoCaptureSession?.addOutput(captureMetadataOutput)
            
            // Set delegate and use the default dispatch queue to execute the call back
            captureMetadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            captureMetadataOutput.metadataObjectTypes = [AVMetadataObject.ObjectType.qr]
            
            // Initialize QR Code Frame to highlight the QR code
            qrCodeFrameView = UIView()
            
        } catch {
            // If any error occurs, simply print it out and don't continue any more.
            print(error)
            return
        }
        
        if let captureSession = videoCaptureSession {
            // Initialize the video preview layer and add it as a sublayer to the viewPreview view's layer.
            videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            videoPreviewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
            videoPreviewLayer?.frame = scannerView.layer.bounds
            scannerView.layer.addSublayer(videoPreviewLayer!)
        }
        
        // Start video capture
        videoCaptureSession?.startRunning()
    }
}
