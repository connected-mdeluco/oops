//
//  CheckoutType.swift
//  Toybox
//
//  Created by cl-dev on 2019-08-21.
//  Copyright © 2019 AppCoda. All rights reserved.
//

import Foundation

enum CheckoutType: Int, Comparable {
    case checkout
    case checkin
    case transfer
    case unavailable

    static let typeMap: [CheckoutType: String] = [
        .checkout: "Borrow",
        .checkin: "Return",
        .transfer: "Transfer",
        .unavailable: "Unavailable"
    ]

    var string: String {
        return CheckoutType.typeMap[self]!
    }

    static func <(lhs: CheckoutType, rhs: CheckoutType) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}
