//
//  ApiResponseModels.swift
//  Toybox
//
//  Created by cl-dev on 2018-09-19.
//  Copyright © 2018 AppCoda. All rights reserved.
//

import Foundation

struct List: Codable {
    var rows: [Employee]
}

struct Device: Codable {
    var name: String
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

