//
//  UIStoryboardSegueWithCompletion.swift
//  Toybox
//
//  Created by cl-dev on 2019-08-19.
//  Copyright © 2019 AppCoda. All rights reserved.
//

import UIKit

class UIStoryboardSegueWithCompletion: UIStoryboardSegue {
    var completion: (() -> Void)?

    override func perform() {
        super.perform()
        guard let completion = completion else { return }
        completion()
    }
}
