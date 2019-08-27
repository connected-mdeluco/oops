//
//  ApiResponseModels.swift
//  Toybox
//
//  Created by cl-dev on 2018-09-19.
//  Copyright © 2018 AppCoda. All rights reserved.
//

import Foundation

struct List<T: Codable>: Codable {
    var rows: [T]
}

struct Device: Codable {
    var identifier: Int
    var name: String
    var assetTag: String
    var status: Status

    var customFields: CustomFields?
    var assignee: Employee?
    var expectedCheckin: Date?
    var lastCheckout: Date?

    init(from decoder: Decoder) throws {
        let valueContainer = try decoder.container(keyedBy: CodingKeys.self)

        self.identifier = try valueContainer.decode(Int.self, forKey: CodingKeys.identifier)
        self.name = try valueContainer.decode(String.self, forKey: CodingKeys.name)
        self.assetTag = try valueContainer.decode(String.self, forKey: CodingKeys.assetTag)
        self.status = try valueContainer.decode(Status.self, forKey: CodingKeys.status)

        self.customFields = try? valueContainer.decode(CustomFields.self, forKey: CodingKeys.customFields)
        self.assignee = try? valueContainer.decode(Employee.self, forKey: CodingKeys.assignee)

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.timeZone = TimeZone.current

        if let expectedCheckinString =
            try? valueContainer.decode(SnipeDateOrDateTime.self, forKey: CodingKeys.expectedCheckin),
            let expectedCheckinDateString = expectedCheckinString.date {
            self.expectedCheckin = dateFormatter.date(from: expectedCheckinDateString)
        }

        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"

        if let lastCheckoutString =
            try? valueContainer.decode(SnipeDateOrDateTime.self, forKey: CodingKeys.lastCheckout),
            let lastCheckoutDateTimeString = lastCheckoutString.datetime {
            self.lastCheckout = dateFormatter.date(from: lastCheckoutDateTimeString)
        }
    }

    struct Status: Codable {
        let statusMeta: StatusMetaTypes

        enum StatusMetaTypes: String, Codable {
            case deployed
            case deployable
            case undeployable
            case pending
        }

        enum CodingKeys: String, CodingKey {
            case statusMeta = "status_meta"
        }
    }

    struct CustomFields: Codable {
        let androidRelease: Release?
        let iosRelease: Release?

        struct Release: Codable {
            let value: String?
        }

        enum CodingKeys: String, CodingKey {
            case androidRelease = "Android Release"
            case iosRelease = "iOS Release"
        }
    }

    struct SnipeDateOrDateTime: Codable {
        let date: String?
        let datetime: String?
    }

    enum CodingKeys: String, CodingKey {
        case identifier = "id"
        case name = "name"
        case assetTag = "asset_tag"
        case status = "status_label"
        case customFields = "custom_fields"
        case assignee = "assigned_to"
        case expectedCheckin = "expected_checkin"
        case lastCheckout = "last_checkout"
    }
}

struct Employee: Codable {
    let name: String
    let id: Int
    
    init(name: String, id: Int) {
        self.name = name
        self.id = id
    }
}

struct DeviceActionResponse: Codable {
    var status: String
}

enum StatusType: String {
    case success = "success"
    case failure = "error"
}

