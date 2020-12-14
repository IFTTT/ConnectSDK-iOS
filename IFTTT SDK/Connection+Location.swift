//
//  Connection+Location.swift
//  IFTTT SDK
//
//  Copyright © 2020 IFTTT. All rights reserved.
//

import Foundation
import CoreLocation

extension Connection.ConnectionStorage {
    var hasLocationTriggers: Bool {
        let closure: (Trigger) -> Bool = {
            switch $0 {
            case .location:
                return true
            }
        }
        
        return allTriggers.contains(where: closure) || activeUserTriggers.contains(where: closure)
    }
    var locationRegions: [CLCircularRegion] {
        return activeUserTriggers.map { (trigger) -> CLCircularRegion in
            switch trigger {
            case .location(let region):
                return region
            }
        }
    }
}
