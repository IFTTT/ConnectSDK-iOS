//
//  LocationService.swift
//  IFTTT SDK
//
//  Copyright © 2020 IFTTT. All rights reserved.
//

import Foundation
import CoreLocation

/// Helps with processing regions from connections and handles storing and uploading location event updates from the system to IFTTT.
final class LocationService: NSObject {
    /// Used to monitor regions.
    private let regionsMonitor: RegionsMonitor
    
    private struct Constants {
        /// According to the CoreLocationManager monitoring docs, the system can only monitor a total of 20 regions.
        static let MaxCoreLocationManagerMonitoredRegionsCount = 20
    }
    
    /// Creates an instance of `LocationService`.
    ///
    /// - Parameters:
    ///     - allowsBackgroundLocationUpdates: Determines whether or not the location manager using in the service should allow for background location updates.
    /// - Returns: An initialized instance of `LocationService`.
    init(allowsBackgroundLocationUpdates: Bool) {
        self.regionsMonitor = RegionsMonitor(allowsBackgroundLocationUpdates: allowsBackgroundLocationUpdates)
        super.init()
    }
}

extension LocationService: ConnectionMonitorSubscriber {
    func processUpdate(with connections: Set<Connection>) {
        var overlappingSet = Set<CLCircularRegion>()
        connections.forEach { connection in
            connection.activeTriggers.forEach { trigger in
                switch trigger {
                case .location(let region): overlappingSet.insert(region)
                }
            }
        }

        regionsMonitor.updateRegions(overlappingSet)
    }
}
