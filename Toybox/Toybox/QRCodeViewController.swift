//
//  QRCodeViewController.swift
//  Toybox
//
//  Created by Simon Ng on 13/10/2016.
//  Copyright © 2016 AppCoda. All rights reserved.
//

import UIKit

class QRCodeViewController: UIViewController {
    
    @IBOutlet weak var returnButton: UIButton!
    @IBOutlet weak var borrowButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        returnButton.layer.cornerRadius = returnButton.frame.height / 2
        returnButton.clipsToBounds = true
        
        borrowButton.layer.cornerRadius = borrowButton.frame.height / 2
        borrowButton.clipsToBounds = true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
    // MARK: - Navigation
    
    @IBAction func unwindToHomeScreen(segue: UIStoryboardSegue) {
        // TODO: create success message?
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let segueDestination = segue.destination
        if segueDestination is QRScannerController {
            (segueDestination as? QRScannerController)?.setScanType(as: QRScannerController.ScanType.returnDevice)
        }
    }
}
