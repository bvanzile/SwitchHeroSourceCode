//
//  ReflectedStringConvertible.swift
//  SwitchHero
//
//  Created by Bryan Van Zile on 4/24/20.
//  Copyright © 2020 Bryan Van Zile. All rights reserved.
//

// Protocol for printing a class to output for debugging purposes

import Foundation

public protocol ReflectedStringConvertible : CustomStringConvertible { }

extension ReflectedStringConvertible {
    public var description: String {
        let mirror = Mirror(reflecting: self)

        var str = "\(mirror.subjectType)("
        var first = true
        for (label, value) in mirror.children {
            if let label = label {
                if first {
                    first = false
                }
                else {
                    str += ", "
                }
                str += label
                str += ": "
                str += "\(value)"
            }
        }
        str += ")"

        return str
    }
}

extension String {
    func capitalizingFirstLetter() -> String {
      return prefix(1).uppercased() + self.lowercased().dropFirst()
    }

    mutating func capitalizeFirstLetter() {
      self = self.capitalizingFirstLetter()
    }
}
