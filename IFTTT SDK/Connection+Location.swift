//
//  Connection+Location.swift
//  IFTTT SDK
//
//  Copyright © 2020 IFTTT. All rights reserved.
//

import Foundation
import CoreLocation

extension Connection {
    var hasLocationTriggers: Bool {
        return activeTriggers.contains(where: {
            switch $0 {
            case .location:
                return true
            }
        })
    }
    var locationRegions: [CLCircularRegion] {
        return activeTriggers.map { (trigger) -> CLCircularRegion in
            switch trigger {
            case .location(let region):
                return region
            }
        }
    }
}

