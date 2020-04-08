//
//  VisitsMonitor.swift
//  IFTTT SDK
//
//  Copyright © 2020 IFTTT. All rights reserved.
//

import Foundation
import CoreLocation

/// Defines a monitor that wraps core location's visits functionality
final class VisitsMonitor: NSObject, CLLocationManagerDelegate, LocationMonitor {
    typealias VisitEvent = (CLVisit) -> Void
    private let locationManager = CLLocationManager()
    
    /// A closure that gets called when a new visit event gets delivered from the system.
    var onVisit: VisitEvent?

    /// Creates an instance of `VisitsMonitor`
    ///
    /// - Parameters:
    ///     - allowsBackgroundLocationUpdates: Determines whether or not the location manager should get background location updates.
    init(allowsBackgroundLocationUpdates: Bool) {
        super.init()

        locationManager.delegate = self
        
        if allowsBackgroundLocationUpdates {
            locationManager.allowsBackgroundLocationUpdates = true
        }
    }
    
    // MARK:- LocationMonitor
    func stopMonitor() {
        locationManager.stopMonitoringVisits()
    }
    
    func startMonitor() {
        locationManager.startMonitoringVisits()
    }
    
    func updateMonitoring(with status: CLAuthorizationStatus) {
        if status == .authorizedAlways {
            locationManager.startMonitoringVisits()
        } else {
            locationManager.stopMonitoringVisits()
        }
    }
    
    // MARK: - CoreLocationManagerDelegate
    func locationManager(_ manager: CLLocationManager, didVisit visit: CLVisit) {
        onVisit?(visit)
    }
    
    deinit {
        locationManager.delegate = nil
    }
}
