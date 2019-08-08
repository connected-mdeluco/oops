//
//  DeviceTableViewCell.swift
//  Toybox
//
//  Created by cl-dev on 2018-09-12.
//  Copyright © 2018 AppCoda. All rights reserved.
//

import UIKit

class DeviceTableViewCell: UITableViewCell {

    @IBOutlet weak private var name: UILabel!
    @IBOutlet weak private var assetTag: UILabel!
    @IBOutlet weak private var status: UILabel!

    var device: Device?

    static var identifier = "deviceCell"

    func configureWithItem(item: Device) {
        name.text =  String(htmlEncodedString: item.name)
        assetTag.text = item.assetTag
        switch item.status.statusMeta {
        case .deployable:
            status.text = "AVAILABLE"
            status.textColor = #colorLiteral(red: 0.4666666687, green: 0.7647058964, blue: 0.2666666806, alpha: 1)
        case .deployed:
            status.text = "\(item.assignee?.name ?? "Unknown")"
            status.textColor = #colorLiteral(red: 0.2549019754, green: 0.2745098174, blue: 0.3019607961, alpha: 1)
        case .pending:
            status.text = "PENDING"
            status.textColor = #colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)
        case .undeployable:
            status.text = "UNAVAILABLE"
            status.textColor = #colorLiteral(red: 0.9372549057, green: 0.3490196168, blue: 0.1921568662, alpha: 1)
        }
        device = item
    }
}

private extension String {

    init(htmlEncodedString: String) {
        self.init()
        guard let encodedData = htmlEncodedString.data(using: .utf8) else {
            self = htmlEncodedString
            return
        }

        let attributedOptions: [NSAttributedString.DocumentReadingOptionKey : Any] = [
            .documentType: NSAttributedString.DocumentType.html,
            .characterEncoding: String.Encoding.utf8.rawValue
        ]

        do {
            let attributedString = try NSAttributedString(data: encodedData, options: attributedOptions, documentAttributes: nil)
            self = attributedString.string
        } catch {
            print("Error: \(error)")
            self = htmlEncodedString
        }
    }
}
