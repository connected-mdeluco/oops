//
//  SnipeAPIManager.swift
//  Toybox
//
//  Created by cl-dev on 2018-09-17.
//  Copyright © 2018 AppCoda. All rights reserved.
//

import Foundation
import PromiseKit
import Alamofire

class SnipeManager {
    
    // MARK: -API
    private static let apiUrl = "https://cl.snipe-it.io/api/v1/"
    private static let apiKeyName = "SnipeKey" // located in Keys.plist
    static let urlPrefix = "https://cl.snipe-it.io/hardware/"
    
    enum ObjectType {
        case deviceObject
        case deviceActionResponseObject
        case listObject
    }
    
    enum CallType: String {
        case hardware = "hardware/"
        case returnHardware = "checkin/"
        case borrowHardware = "checkout/"
        case user = "users/"
    }

    enum Locations: Int {
        case safes = 4
        case fuji = 20
    }
    
    private static func getAPIKey(keyname: String) -> String {
        let filePath = Bundle.main.path(forResource: "Keys", ofType: "plist")
        let plist = NSDictionary(contentsOfFile: filePath!)
        var apiKey: String = plist?.object(forKey: keyname) as! String
        return apiKey
    }
    
    // MARK: -Device
    
    static func patchDeviceName(withId id: String, forName name: String) {
        guard let unwrappedUrl = URL(string: apiUrl + CallType.hardware.rawValue + id) else { return }
        
        let key = getAPIKey(keyname: apiKeyName)
        
        var request = URLRequest(url: unwrappedUrl)
        request.httpMethod = HTTPMethod.patch.rawValue
        request.setValue(key, forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ["name": name]
        let jsonData = try? JSONSerialization.data(withJSONObject: body, options: [])
        request.httpBody = jsonData
        
        Alamofire.request(request)
    }
    
    static func getDevice(forId id: String) -> Promise<Device> {
        guard let unwrappedUrl = URL(string: apiUrl + CallType.hardware.rawValue + id)
            else {
                return Promise { seal in
                    seal.reject(ErrorManager.SnipeError.genericError)
                }
        }
        
        let key = getAPIKey(keyname: apiKeyName)
        
        return Promise { seal in
            Alamofire
                .request(unwrappedUrl,
                         method: .get,
                         parameters: nil,
                         encoding: URLEncoding.default,
                         headers: ["Authorization":key])
                .responseData(completionHandler: { (response) in
                    switch response.result {
                    case .success(let json):
                        if let result = decodeObject(json, forType: ObjectType.deviceObject) as? Device {
                            seal.fulfill(result)
                        } else {
                            if let statusCode = response.response?.statusCode {
                                if statusCode == 200 {
                                    seal.reject(ErrorManager.SnipeError.apiKeyInvalid)
                                } else if statusCode == 404 {
                                    seal.reject(ErrorManager.SnipeError.invalidApiCall)
                                }
                            } else {
                                seal.reject(ErrorManager.SnipeError.genericError)
                            }
                        }
                    case .failure:
                        seal.reject(ErrorManager.SnipeError.noConnectionAvailable)
                    }
                })
        }
    }
    
    static func borrowDevice(withId id: String, toEmployee user: String) -> Promise<String> {
        guard let unwrappedUrl = URL(string: apiUrl
                                            + CallType.hardware.rawValue
                                            + id + "/"
                                            + CallType.borrowHardware.rawValue)
       else {
            return Promise { seal in
                seal.reject(ErrorManager.SnipeError.genericError)
            }
        }
        
        let key = getAPIKey(keyname: apiKeyName)
        
        var request = URLRequest(url: unwrappedUrl)
        request.httpMethod = HTTPMethod.post.rawValue
        request.setValue(key, forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        var body = ["checkout_to_type": "user", "assigned_user": user]

        let expectedReturnDayCode = 6 // Friday

        let calendar = Calendar(identifier: .gregorian)
        let today = Date()

        let expectedReturnDayComponents = DateComponents(calendar: calendar, weekday: expectedReturnDayCode)
        let todayComponents = calendar.dateComponents([.weekday], from: today)

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        if todayComponents.weekday != expectedReturnDayCode,
            let expectedReturnDate = calendar.nextDate(after: Date(), matching: expectedReturnDayComponents, matchingPolicy: .nextTime) {
            let expectedCheckin = formatter.string(from: expectedReturnDate)
            body["expected_checkin"] = expectedCheckin
        } else {
            let expectedCheckin = formatter.string(from: today)
            body["expected_checkin"] = expectedCheckin
        }

        let jsonData = try? JSONSerialization.data(withJSONObject: body, options: [])
        request.httpBody = jsonData
        
        return Promise { seal in
            Alamofire.request(request) // TODO: create header member variable
                .responseData(completionHandler: { (response) in
                    switch(response.result) {
                    case .success(let json):
                        if let result = decodeObject(json, forType: ObjectType.deviceActionResponseObject) as? DeviceActionResponse {
                            seal.fulfill(result.status)
                        } else {
                            if let statusCode = response.response?.statusCode {
                                if statusCode == 200 {
                                    seal.reject(ErrorManager.SnipeError.apiKeyInvalid)
                                } else if statusCode == 404 {
                                    seal.reject(ErrorManager.SnipeError.invalidApiCall)
                                }
                            } else {
                                seal.reject(ErrorManager.SnipeError.genericError)
                            }
                        }
                    case .failure:
                        seal.reject(ErrorManager.SnipeError.noConnectionAvailable)
                    }
                })
            }
    }
    
    static func returnDevice(device: Device) -> Promise<String> {
        guard let unwrappedUrl = URL(string: apiUrl + CallType.hardware.rawValue + "\(device.identifier)" + "/" + CallType.returnHardware.rawValue)
        else {
            return Promise<String> { seal in
                seal.reject(ErrorManager.SnipeError.genericError)
            }
        }
        
        let key = getAPIKey(keyname: apiKeyName)

        var request = URLRequest(url: unwrappedUrl)
        request.httpMethod = HTTPMethod.post.rawValue
        request.setValue(key, forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        var body: [String: Any] = ["name": device.name]

        if device.assetTag.uppercased().hasPrefix("FB") {
            body["location_id"] = Locations.fuji.rawValue
        } else {
            body["location_id"] = Locations.safes.rawValue
        }

        let jsonData = try? JSONSerialization.data(withJSONObject: body, options: [])
        request.httpBody = jsonData

        return Promise { seal in
            Alamofire
                .request(request)
                .responseData(completionHandler: { (response) in
                    switch(response.result) {
                    case .success(let json):
                        if let result = decodeObject(json, forType: ObjectType.deviceActionResponseObject) as? DeviceActionResponse {
                            seal.fulfill(result.status)
                        } else {
                            if let statusCode = response.response?.statusCode {
                                if statusCode == 200 {
                                    seal.reject(ErrorManager.SnipeError.apiKeyInvalid)
                                } else if statusCode == 404 {
                                    seal.reject(ErrorManager.SnipeError.invalidApiCall)
                                }
                            } else {
                                seal.reject(ErrorManager.SnipeError.genericError)
                            }
                        }
                    case .failure:
                        seal.reject(ErrorManager.SnipeError.noConnectionAvailable)
                    }
                })
        }
    }
    
    // MARK: -User
    
    static func getUserList() -> Promise<[Employee]> {
        
        guard let unwrappedUrl = URL(string: apiUrl + CallType.user.rawValue)
            else { return Promise<[Employee]> { seal in
                seal.reject(ErrorManager.SnipeError.genericError)
                }
        }
        
        let theKey = getAPIKey(keyname: apiKeyName)
    
        let parameters = ["limit": "500", "order": "asc"]
        
        return Promise { seal in
            Alamofire
                .request(unwrappedUrl,
                         method: .get,
                         parameters: parameters,
                         encoding: URLEncoding.default,
                         headers: ["Authorization":theKey])
                .responseData(completionHandler: { (response) in
                    switch response.result {
                    case .success(let json):
                        if let result = decodeObject(json, forType: ObjectType.listObject) as? List {
                            seal.fulfill(result.rows)
                        } else {
                            if let statusCode = response.response?.statusCode {
                                if statusCode == 200 {
                                    seal.reject(ErrorManager.SnipeError.apiKeyInvalid)
                                } else if statusCode == 404 {
                                    seal.reject(ErrorManager.SnipeError.invalidApiCall)
                                }
                            } else {
                                seal.reject(ErrorManager.SnipeError.genericError)
                            }
                        }
                    case .failure:
                        seal.reject(ErrorManager.SnipeError.noConnectionAvailable)
                    }
                })
        }
    }
    
    private static func decodeObject(_ response: Data, forType type: ObjectType) -> Any? {
        let jsonString = String(data: response, encoding: .utf8)
        let jsonData = jsonString?.data(using: .utf8)
        if let unwrappedJsonData = jsonData {
            switch(type) {
            case .deviceObject:
                let device = try? JSONDecoder().decode(Device.self, from: unwrappedJsonData)
                return device
            case .deviceActionResponseObject:
                let deviceActionResponse = try? JSONDecoder().decode(DeviceActionResponse.self, from: unwrappedJsonData)
                return deviceActionResponse
            case .listObject:
                let employeesList = try? JSONDecoder().decode(List.self, from: unwrappedJsonData)
                return employeesList
            }
        } else {
            return nil
        }
    }
}

