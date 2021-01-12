//
//  Date.swift
//  SwitchHero
//
//  Created by Bryan Van Zile on 6/4/20.
//  Copyright © 2020 Bryan Van Zile. All rights reserved.
//

import Foundation

extension Date {
    var unixTimestampMS: Int64 {
        return Int64((self.timeIntervalSince1970 * 1000.0).rounded())
    }

    init(milliseconds: Int) {
        self = Date(timeIntervalSince1970: TimeInterval(milliseconds / 1000))
    }
}
