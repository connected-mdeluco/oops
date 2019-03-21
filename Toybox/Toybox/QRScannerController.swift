//
//  QRScannerController.swift
//  Toybox
//
//  Created by Simon Ng on 13/10/2016.
//  Copyright © 2016 AppCoda. All rights reserved.
//

import UIKit
import AVFoundation
import PromiseKit

class QRScannerController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {

    @IBOutlet weak var deviceActionButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var footerOpaqueView: UIView!
    @IBOutlet weak var headerOpaqueView: UIView!
    @IBOutlet weak var userLabel: UILabel!
    
    private var scanType: ScanType = ScanType.returnDevice // default value
    private var employee: Employee?
    private var deviceIds = [String]()
    
    var devices = [String: Device]()
    var videoCaptureSession: AVCaptureSession?
    var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    var qrCodeFrameView: UIView?
    var player: AVAudioPlayer?
    
    // MARK: -View setup/Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.title = "\(scanType.rawValue) devices for \(String(describing: employee?.name))"
        
        if let employeeName = employee?.name {
            userLabel.text = employeeName + opaqueHeaderBorrowingDevices
        } else {
            userLabel.text = opaqueHeaderReturningDevices
        }
        
        setUpVideoCaptureSession()
        bringScanPageSubviewsToFront()
        setUpDeviceActionButton()
        setUpCancelButton()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
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
            videoPreviewLayer?.frame = view.layer.bounds
            view.layer.addSublayer(videoPreviewLayer!)
        }
        
        // Start video capture
        videoCaptureSession?.startRunning()
    }
    
    func bringScanPageSubviewsToFront() {
        view.bringSubviewToFront(footerOpaqueView)
        view.bringSubviewToFront(deviceActionButton)
        view.bringSubviewToFront(cancelButton)
        view.bringSubviewToFront(headerOpaqueView)
        view.bringSubviewToFront(userLabel)
    }
    
    func refreshCaptureSession() {
        self.videoCaptureSession?.startRunning()
        self.qrCodeFrameView?.frame = CGRect.zero
    }
    
    func setUpDeviceActionButton() {
        switch(scanType) {
        case .returnDevice:
            deviceActionButton.setTitle(defaultReturnButtonText, for: .normal)
        case .borrowDevice:
            deviceActionButton.setTitle(defaultBorrowButtonText, for: .normal)
        }
        deviceActionButton.titleLabel?.textColor = .black
        deviceActionButton.isEnabled = false
        deviceActionButton.backgroundColor = .lightGray
        deviceActionButton.layer.cornerRadius = deviceActionButton.frame.height / 2
    }
    
    func setUpCancelButton() {
        cancelButton.layer.cornerRadius = deviceActionButton.frame.height / 2
    }
    
    func updateDeviceActionButton(forDeviceCount count: Int) {
        switch(scanType) {
        case .returnDevice:
            let returnDevicesText = returnMultipleDevicesButtonText.replacingOccurrences(of: "%", with: String(count))
            deviceActionButton.setTitle(returnDevicesText, for: .normal)
        case .borrowDevice:
            let borrowDevicesText = borrowMultipleDevicesButtonText.replacingOccurrences(of: "%", with: String(count))
            deviceActionButton.setTitle(borrowDevicesText, for: .normal)
        }
        if(count == 1) {
            let buttonTitle = deviceActionButton.titleLabel?.text
            deviceActionButton.setTitle(buttonTitle, for: .normal)
        }
        deviceActionButton.backgroundColor = UIColor(red: 0, green: 104/255, blue: 196/255, alpha: 1)
        deviceActionButton.setTitleColor(UIColor.white, for: .normal)
        deviceActionButton.isEnabled = true
    }
    
    @IBAction func doneDeviceScan(_ sender: UIButton) {
        self.present(createDeviceConfirmationAlert(), animated: true, completion: nil)
    }
}

// MARK: -Alert

extension QRScannerController {
    
    func createDeviceConfirmationAlert() -> UIAlertController {
        let deviceNames = listOfDeviceNames()
        let deviceConfirmationAlert = UIAlertController(title: deviceScanConfirmationTitle + scanType.rawValue + ":",
                                                        message: deviceNames,
                                                        preferredStyle: .alert)
        // TODO: device confirmation alert is overriding potential error alerts.
        switch(scanType) {
        case .borrowDevice:
            deviceIds.forEach { (device) in
                tryDeviceBorrow(device, completion: nil)
            }
        case .returnDevice:
            deviceIds.forEach { (deviceId) in
                if let device = devices[deviceId] {
                    tryDeviceReturn(device, completion: nil)
                }
            }
        }
        deviceConfirmationAlert.addAction(UIAlertAction(title: alertTextOk, style: .default, handler: { _ in
            deviceConfirmationAlert.dismiss(animated: false, completion: nil)
            self.performSegue(withIdentifier: unwindFromAlertOnScanView, sender: self)
        }))
        deviceConfirmationAlert.addAction(UIAlertAction(title: alertTextCancel, style: .cancel, handler: { _ in
            deviceConfirmationAlert.dismiss(animated: false, completion: nil)
            if let navigationController = self.navigationController {
                navigationController.popViewController(animated: true)
            } else {
                self.performSegue(withIdentifier: unwindFromAlertOnScanView, sender: self)
            }
        }))
        return deviceConfirmationAlert
    }
    
    func presentInvalidQRCodeAlert() {
        let invalidQRAlert = UIAlertController(title: invalidQRCodeAlertTitle,
                                               message: invalidQRCodeAlertMessage,
                                               preferredStyle: .alert)
        invalidQRAlert.addAction(UIAlertAction(title: alertTextOk, style: .default, handler: { _ in
            invalidQRAlert.dismiss(animated: true, completion: nil)
            self.refreshCaptureSession()
        }))
        self.present(invalidQRAlert, animated: true, completion: nil)
    }
    
    func presentDeviceScanSuccessAlert() {
        let deviceConfirmationAlert = UIAlertController(title: deviceScanSuccessAlertTitle,
                                               message: devicesScanSuccessAlertMessage,
                                               preferredStyle: .alert)
        deviceConfirmationAlert.addAction(UIAlertAction(title: alertTextOk, style: .cancel, handler: { _ in
            self.refreshCaptureSession()
        }))
        self.present(deviceConfirmationAlert, animated: true, completion: nil)
        let delayTime = DispatchTime.now() + 1.0
        DispatchQueue.main.asyncAfter(deadline: delayTime, execute: {
            deviceConfirmationAlert.dismiss(animated: true, completion: nil)
            self.refreshCaptureSession()
        })
    }
}

// MARK: -QR

extension QRScannerController {
    
    func isValidQRCode(_ message: String) -> Bool {
        return message.hasPrefix(SnipeManager.urlPrefix)
    }
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        
        if metadataObjects.count == 0 {
            qrCodeFrameView?.frame = CGRect.zero
            return
        }
        
        // Get the metadata object
        let metadataObj = metadataObjects[0] as! AVMetadataMachineReadableCodeObject
        if metadataObj.type == AVMetadataObject.ObjectType.qr {
            createQRBorder(metadataObj)
            var messageText: String = ""
            
            // Retrieve string message from metadata
            if metadataObj.stringValue != nil {
                if let unwrappedMessageText = metadataObj.stringValue {
                    messageText = unwrappedMessageText
                }
            }
            
            if isValidQRCode(messageText) {
                let deviceId = parseQRMessage(messageText)
                if let id = deviceId {
                    appendDeviceBy(id: id)
                }
            } else {
                presentInvalidQRCodeAlert()
                playSound(withName: unacceptableSound)
            }
        }
    }
    
    func parseQRMessage(_ message: String) -> String? {
        let range = SnipeManager.urlPrefix.startIndex..<SnipeManager.urlPrefix.endIndex
        var mutableMessage = message
        mutableMessage.removeSubrange(range)
        let id = Int(mutableMessage)
        if id != nil && !deviceIds.contains(mutableMessage) {
            deviceIds.append(mutableMessage)
            return mutableMessage
        }
        return nil
    }
    
    func createQRBorder(_ metadataObj : AVMetadataObject) {
        let barCodeObject = videoPreviewLayer?.transformedMetadataObject(for: metadataObj)
        qrCodeFrameView?.frame = barCodeObject!.bounds
        qrCodeFrameView?.layer.borderColor = UIColor.green.cgColor
        qrCodeFrameView?.layer.borderWidth = 2
        view.addSubview(qrCodeFrameView!)
        view.bringSubviewToFront(qrCodeFrameView!)
    }
}

// MARK: -Device methods

extension QRScannerController {
    func listOfDeviceNames() -> String? {
        var deviceNames: String? = ""
        devices.forEach({ (deviceId, device) in
            deviceNames?.append("\(device.name)\n")
        })
        deviceNames?.removeLast()
        return deviceNames
    }
    
    func appendDeviceBy(id: String) {
        let promise = SnipeManager.getDevice(forId: id)
        promise.done { result in
            let device = result as Device
            self.devices.updateValue(device, forKey: id)
            self.updateDeviceActionButton(forDeviceCount: self.deviceIds.count)
            self.videoCaptureSession?.stopRunning()
            self.presentDeviceScanSuccessAlert()
            self.playSound(withName: dingSound)
            }.catch { (error) in
                let snipeError = error as! ErrorManager.SnipeError
                ErrorManager.handleError(ofType: snipeError, withDevice: nil, fromInstance: self)
        }
    }
    
    func tryDeviceBorrow(_ deviceId: String, completion: ((_ success: Bool) -> Void)?) {
         let promise = SnipeManager.borrowDevice(withId: deviceId, toEmployee: String(employee!.id))
        var responseSucceeded = false
        promise.done({ [weak self] (status) in
            switch(status) {
            case StatusType.success.rawValue:
                responseSucceeded = true
            case StatusType.failure.rawValue:
                ErrorManager.handleError(ofType: .deviceAlreadyBorrowed,
                                         withDevice: self?.devices[deviceId],
                                         fromInstance: self)
            default:
                ErrorManager.handleError(ofType: .noConnectionAvailable,
                                         withDevice: nil,
                                         fromInstance: self)
            }
            completion?(responseSucceeded)
        }).catch({ [weak self] (error) in
            let snipeError = error as! ErrorManager.SnipeError
            ErrorManager.handleError(ofType: snipeError,
                                     withDevice: self?.devices[deviceId],
                                     fromInstance: self)
            completion?(responseSucceeded)
        })
    }
    
    func tryDeviceReturn(_ device: Device, completion: ((_ success: Bool) ->Void)?) {
        var responseSucceeded = false
        let promise = SnipeManager.returnDevice(device: device)
        promise.done({ (status) in
            switch(status) {
            case StatusType.success.rawValue:
                responseSucceeded = true
            case StatusType.failure.rawValue:
                ErrorManager.handleError(ofType: .deviceAlreadyReturned,
                                         withDevice: device,
                                         fromInstance: self)
            default:
                ErrorManager.handleError(ofType: .noConnectionAvailable,
                                         withDevice: nil,
                                         fromInstance: self)
            }
            completion?(responseSucceeded)
        }).catch({ (error) in
            let snipeError = error as! ErrorManager.SnipeError
            ErrorManager.handleError(ofType: snipeError,
                                     withDevice: nil,
                                     fromInstance: self)
            responseSucceeded = false
            completion?(responseSucceeded)
        })
    }
}

// MARK: -Audio Player

extension QRScannerController {
    func playSound(withName name: String) {
        guard let audioSource = Bundle.main.url(forResource: name, withExtension: "mp3") else { return }
        
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)

            player = try AVAudioPlayer(contentsOf: audioSource, fileTypeHint: AVFileType.mp3.rawValue)

            guard let player = player else { return }

            player.play()
        } catch let error {
            print(error.localizedDescription)
        }
    }
}

// MARK: -Scan type

extension QRScannerController {
    enum ScanType: String {
        case returnDevice = "returning"
        case borrowDevice = "borrowing"
    }
    
    func setScanType(as scanType: ScanType) {
        self.scanType = scanType
    }

    func setEmployee(as employee: Employee) {
        self.employee = employee
    }
}
