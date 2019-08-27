//
//  DeviceTableViewCell.swift
//  Toybox
//
//  Created by cl-dev on 2019-08-27.
//  Copyright © 2019 AppCoda. All rights reserved.
//

import UIKit

class DeviceTableViewCell: UITableViewCell {
    @IBOutlet var statusLabel: UILabel!
    @IBOutlet var verticalStackView: UIStackView!
    @IBOutlet var deviceNameLabel: UILabel!
    @IBOutlet var expectedLabel: UILabel!

    var expectedAttributedString: NSAttributedString = NSAttributedString() {
        didSet {
            expectedLabel.attributedText = expectedAttributedString
            if expectedAttributedString.length == 0 {
                verticalStackView.removeArrangedSubview(expectedLabel)
                expectedLabel.removeFromSuperview()
            } else if !verticalStackView.arrangedSubviews.contains(expectedLabel) {
                verticalStackView.addArrangedSubview(expectedLabel)
            }
        }
    }

    let overdueString = NSAttributedString(string: " OVERDUE", attributes: [NSAttributedString.Key.foregroundColor: UIColor.red])

    func clear() {
        statusLabel.text = ""
        deviceNameLabel.text = ""
        expectedLabel.text = ""
    }

    func update(with device: Device) {
        let status = device.status.statusMeta
        statusLabel.text = status == .deployable ? "✅" : "⭕️"
        deviceNameLabel.text = device.name

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "E, MMM dd"
        if let expectedCheckin = device.expectedCheckin {
            let attStr = NSMutableAttributedString(string: "Expected \(dateFormatter.string(from: expectedCheckin))")
            if expectedCheckin.timeIntervalSinceNow.sign == .minus {
                attStr.append(overdueString)
            }
            expectedAttributedString = NSAttributedString(attributedString: attStr)
        } else {
            expectedAttributedString = NSAttributedString()
        }
    }

}
