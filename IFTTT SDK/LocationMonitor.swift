//
//  LocationMonitor.swift
//  IFTTT SDK
//
//  Copyright © 2020 IFTTT. All rights reserved.
//

import Foundation
import CoreLocation

/// A core protocol to expose CoreLocation's location monitoring.
protocol LocationMonitor {
    /// Starts the monitoring
    func startMonitor()
    
    /// Stops the monitoring
    func stopMonitor()
    
    /// Starts or stops the monitoring based on the user's location authorization status.
    /// By default, this method starts the monitor if the user has given Always authorization for location and stops it otherwise.
    ///
    /// - Parameters:
    ///     - status: The user's permission level for location.
    func updateMonitoring(with status: CLAuthorizationStatus)
}

extension LocationMonitor {
    func updateMonitoring(with status: CLAuthorizationStatus) {
        if status == .authorizedAlways || status == .authorizedWhenInUse {
            startMonitor()
        } else {
            stopMonitor()
        }
    }
}
