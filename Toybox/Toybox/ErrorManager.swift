//
//  ErrorManager.swift
//  Toybox
//
//  Created by cl-dev on 2018-09-21.
//  Copyright © 2018 AppCoda. All rights reserved.
//

import Foundation
import UIKit

class ErrorManager: UIViewController {

    enum SnipeError: Error {
        case genericError
        case noConnectionAvailable
        case apiKeyInvalid
        case invalidApiCall
        case deviceAlreadyBorrowed
        case deviceAlreadyReturned
    }
    
    static func handleError(ofType type: SnipeError, withDevice device: Device?, fromInstance instance: UIViewController?) {
        switch(type) {
        case .genericError:
            presentErrorAlert(onView: instance, message: genericErrorMessage)
        case .noConnectionAvailable:
            presentErrorAlert(onView: instance, message: noInternetConnectionAlertMessage)
        case .apiKeyInvalid:
            presentErrorAlert(onView: instance, message: apiKeyInvalidAlertMessage)
        case .invalidApiCall:
            presentErrorAlert(onView: instance, message: invalidApiCallAlertMessage)
        case .deviceAlreadyBorrowed:
            break
        case .deviceAlreadyReturned:
            print("device already returned")
        }
    }
}

extension ErrorManager {
    
    private static func presentErrorAlert(onView instance: UIViewController?, message: String) {
        let apiIncompleteAlert = UIAlertController(title: errorAlertTitle, message: message, preferredStyle: .alert)
        apiIncompleteAlert.addAction(UIAlertAction(title: alertTextOk, style: .cancel, handler: { _ in
            apiIncompleteAlert.dismiss(animated: true, completion: nil)
            instance?.dismiss(animated: true, completion: nil)
        }))
        if let unwrappedInstance = instance {
            unwrappedInstance.present(apiIncompleteAlert, animated: true, completion: nil)
        }
    }
}
