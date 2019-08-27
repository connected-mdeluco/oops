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

    var expectedLabelText: String = "" {
        didSet {
            expectedLabel.text = expectedLabelText
            if expectedLabelText.count == 0 {
                verticalStackView.removeArrangedSubview(expectedLabel)
            } else if !verticalStackView.arrangedSubviews.contains(expectedLabel) {
                verticalStackView.addArrangedSubview(expectedLabel)
            }
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

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
            expectedLabelText = "Expected \(dateFormatter.string(from: expectedCheckin))"
        } else {
            expectedLabelText = ""
        }
    }

}
