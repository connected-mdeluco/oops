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
    let identifier: Int
    let name: String
    let assetTag: String

    let status: Status

    let customFields: CustomFields?

    let assignee: Employee?

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

    enum CodingKeys: String, CodingKey {
        case identifier = "id"
        case name = "name"
        case assetTag = "asset_tag"
        case status = "status_label"
        case customFields = "custom_fields"
        case assignee = "assigned_to"
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

