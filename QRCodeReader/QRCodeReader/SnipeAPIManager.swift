//
//  SnipeAPIManager.swift
//  QRCodeReader
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
    
    /* TODO: Add information about API key location in README
     */
    
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
    
    private static func getAPIKey(keyname: String) -> String {
        let filePath = Bundle.main.path(forResource: "Keys", ofType: "plist")
        let plist = NSDictionary(contentsOfFile: filePath!)
        var apiKey: String = plist?.object(forKey: keyname) as! String
        apiKey.removeLast()
        apiKey.removeFirst()
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
    
    static func getDeviceName(forId id: String) -> Promise<String> {
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
                            seal.fulfill(result.name)
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

        let body = ["checkout_to_type": "user", "assigned_user": user]
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
    
    static func returnDevice(withId id: String) -> Promise<String> {
        guard let unwrappedUrl = URL(string: apiUrl + CallType.hardware.rawValue + id + "/" + CallType.returnHardware.rawValue)
        else {
            return Promise<String> { seal in
                seal.reject(ErrorManager.SnipeError.genericError)
            }
        }
        
        let key = getAPIKey(keyname: apiKeyName)
        
        return Promise { seal in
            Alamofire
                .request(unwrappedUrl,
                         method: .post,
                         parameters: nil,
                         encoding: URLEncoding.default,
                         headers: ["Authorization":key])
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

