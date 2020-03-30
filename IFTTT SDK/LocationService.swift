//
//  LocationService.swift
//  IFTTT SDK
//
//  Copyright © 2020 IFTTT. All rights reserved.
//

import Foundation
import CoreLocation

/**
 Monitors a set of regions associated with the user's applets.
 Caps the number of regions monitored by the system to `Constants.MaxCoreLocationManagerMonitoredRegionsCount`.
 Once the monitored regions associated with applets exceeds `Constants.MaxCoreLocationManagerMonitoredRegionsCount`, the service starts monitoring visits the user makes to only monitor the `Constants.MaxCoreLocationManagerMonitoredRegionsCount` closest regions to the user's location.
*/
final class LocationService: NSObject {
    /// Describes an region event initiated by region monitoring.
    typealias RegionEvent = (CLRegion) -> Void
    
    /// Describes a failure in region monitoring.
    typealias RegionMonitorFailEvent = (CLRegion?, Error) -> Void
    
    /// Describes a location authorization event initiated by the user or when adding monitored regions.
    typealias LocationAuthorizationEvent = (CLAuthorizationStatus, CLLocationManager) -> Void
    
    /// Closure that gets called when monitoring begins for a specific region.
    var didStartMonitoringRegion: RegionEvent?
    
    /// Closure that gets called when monitoring fails for a specific region.
    var didFailMonitoringRegion: RegionMonitorFailEvent?
    
    /// Closure that gets called when the user enters a region.
    var didEnterRegion: RegionEvent?
    
    /// Closure that gets called when the user exits a region.
    var didExitRegion: RegionEvent?
    
    /// The set of all monitored regions. Updated by the `updateRegions` method.
    private var allMonitoredRegions = Set<CLRegion>()

    /// The location manager used to monitor regions and visits
    private let locationManager = CLLocationManager()
    
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
        super.init()
        
        locationManager.delegate = self
        locationManager.allowsBackgroundLocationUpdates = allowsBackgroundLocationUpdates
        if #available(iOS 11.0, *) {
            locationManager.showsBackgroundLocationIndicator = true
        }
    }
    
    // MARK: - Public API
    
    /// Starts monitoring of parameter regions. Starts monitoring visits if needed.
    ///
    /// - Parameters:
    ///     - regions: The set of regions to monitor.
    func startMonitoringRegions(_ regions: Set<CLRegion>) {
        self.allMonitoredRegions = regions
        updateMonitoring(with: CLLocationManager.authorizationStatus())
    }
    
    /// Stops monitoring of parameter regions. Stops monitoring visits if needed.
    ///
    /// - Parameters:
    ///     - regions: The set of regions to un-monitor.
    func stopMonitoringRegions(_ regions: Set<CLRegion>) {
        regions.forEach {
            locationManager.stopMonitoring(for: $0)
            allMonitoredRegions.remove($0)
        }
        if !shouldStartVisitsMonitoring() {
            locationManager.stopMonitoringVisits()
        }
    }
    
    // MARK: - Private Methods
    
    /// Stops region monitoring and visits monitoring.
    private func stopMonitor() {
        allMonitoredRegions.forEach { (region) in
            if CLLocationManager.isMonitoringAvailable(for: type(of: region)) {
                locationManager.stopMonitoring(for: region)
            }
        }
        locationManager.stopMonitoringVisits()
    }
    
    /// Starts region monitoring for the regions set on the service.
    private func startMonitor() {
        let monitoredRegions = locationManager.monitoredRegions
        // Go through the new regions we got passed in and start monitoring those regions if they're not being monitored
        allMonitoredRegions.forEach { (region) in
            if !monitoredRegions.contains(region) && CLLocationManager.isMonitoringAvailable(for: type(of: region)) {
                locationManager.startMonitoring(for: region)
            }
        }
    }
    
    /// Updates the monitoring of regions set on the service.
    private func updateMonitoring(with status: CLAuthorizationStatus) {
        switch status {
        case .authorizedAlways:
            if shouldStartVisitsMonitoring() {
                /*
                 If we need to start visits monitoring then we can't start the region monitor right now.
                 We have to wait until we know where the user is before we can start monitoring regions. ]
                 This is due to the system only allowing for monitoring a maximum of 20 regions.
                 */
                locationManager.startMonitoringVisits()
            } else {
                startMonitor()
            }
        default:
            locationManager.stopMonitoringVisits()
            stopMonitor()
        }
    }
    
    /// Determines whether or not the visitsMonitor needs to be started or not.
    /// Checks to see what locations are currently being monitored, what locations we need to monitor, and the intersection of these sets.
    /// If the value: count of the currently monitored regions + (count of regions we want to monitor - count of intersection of those sets) > `Constants.MaxCoreLocationManagerMonitoredRegionsCount` then we return true otherwise we return false
    ///
    /// - returns: A boolean value that determines whether or not we need to start visits monitoring.
    private func shouldStartVisitsMonitoring() -> Bool {
        let currentlyMonitoredRegions = locationManager.monitoredRegions
        let intersection = currentlyMonitoredRegions.intersection(allMonitoredRegions)
        
        return (currentlyMonitoredRegions.count + (allMonitoredRegions.count - intersection.count)) > Constants.MaxCoreLocationManagerMonitoredRegionsCount
    }
    
    /// Updates the list of registered regions around the parameter visit.
    ///
    /// - Parameters:
    ///     - visit: The visit to use in determining what regions get monitored. Only the 20 closest regions to this visit get monitored.
    private func update(around visit: CLVisit) {
        let visitLocation = CLLocation(latitude: visit.coordinate.latitude, longitude: visit.coordinate.longitude)
        let regionsClosestToLocation = allMonitoredRegions.compactMap { $0 as? CLCircularRegion }
            .sorted { (region1, region2) -> Bool in
                let region1Location = CLLocation(latitude: region1.center.latitude, longitude: region1.center.longitude)
                let region2Location = CLLocation(latitude: region2.center.latitude, longitude: region2.center.longitude)
                return visitLocation.distance(from: region1Location) < visitLocation.distance(from: region2Location)
            }
        let topClosest = regionsClosestToLocation[..<Constants.MaxCoreLocationManagerMonitoredRegionsCount]

        startMonitoringRegions(Set(topClosest))
    }
    
    deinit {
        locationManager.delegate = nil
    }
}

extension LocationService: ConnectionMonitorSubscriber {
    func processUpdate(with connection: Connection) {
        func regions(matching statuses: Set<Connection.Status>) -> Set<CLCircularRegion> {
            guard statuses.contains(connection.status) else { return .init() }
            
            return connection.activeTriggers.compactMap { (trigger) -> CLCircularRegion? in
                switch trigger {
                case .location(let region): return region
                }
            }
        }
        
        let monitoredRegions = regions(matching: [.enabled])
        let unmonitoredRegions = regions(matching: [.disabled, .unknown, .initial])
        
        monitor(toStart: monitoredRegions, toStop: unmonitoredRegions)
    }
    
    private func monitor(toStart: Set<CLRegion>, toStop: Set<CLRegion>) {
        guard CLLocationManager.locationServicesEnabled() else { return }
        
        DispatchQueue.main.async { [weak self] in
            self?.stopMonitoringRegions(toStop)
            self?.startMonitoringRegions(toStart)
        }
    }
}

extension LocationService: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didStartMonitoringFor region: CLRegion) {
        didStartMonitoringRegion?(region)
    }
    
    func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
        didFailMonitoringRegion?(region, error)
    }
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        didEnterRegion?(region)
    }
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        didExitRegion?(region)
    }
    
    func locationManager(_ manager: CLLocationManager, didVisit visit: CLVisit) {
        update(around: visit)
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        updateMonitoring(with: status)
    }
}
