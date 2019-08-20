//
//  UIStoryboardSegueWithCompletion.swift
//  Toybox
//
//  Created by cl-dev on 2019-08-19.
//  Copyright © 2019 AppCoda. All rights reserved.
//

import UIKit

/*
 * Enables view-related actions after segue has compeleted.
 * https://stackoverflow.com/a/37602422
 */
class UIStoryboardSegueWithCompletion: UIStoryboardSegue {
    var completion: (() -> Void)?

    override func perform() {
        super.perform()
        guard let completion = completion else { return }
        completion()
    }
}
