//
//  Array.swift
//  SwitchHero
//
//  Created by Bryan Van Zile on 6/5/20.
//  Copyright © 2020 Bryan Van Zile. All rights reserved.
//

import Foundation

extension Array {
    mutating func replaceOrAppend(_ item: Element, whereFirstIndex predicate: (Element) -> Bool) {
        if let idx = self.firstIndex(where: predicate) {
            self[idx] = item
        }
        else {
            append(item)
        }
    }
}
