//
//  Set+Helpers.swift
//  IFTTT SDK
//
//  Copyright © 2020 IFTTT. All rights reserved.
//

import Foundation

extension Set {
    func map<U>(transform: (Element) -> U) -> Set<U> {
        return Set<U>(lazy.map(transform))
    }
    
    func compactMap<U>(_ transform: (Element) -> U?) -> Set<U> {
        return Set<U>(lazy.compactMap(transform))
    }
}
