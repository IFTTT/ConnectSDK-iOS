//
//  RegionsMonitor.swift
//  IFTTT SDK
//
//  Copyright © 2020 IFTTT. All rights reserved.
//

import Foundation
import CoreLocation

/// Wrapper around `CLCircularRegion` to provide easy overriding of `Hashable`.
fileprivate struct IFTTTCircularRegion: Hashable {
    let region: CLCircularRegion
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(region.identifier)
        hasher.combine(region.center.latitude)
        hasher.combine(region.center.longitude)
        hasher.combine(region.radius)
    }
}

/**
 Monitors a set of regions associated with the user's applets.
 Caps the number of regions monitored by the system to `Constants.MaxCoreLocationManagerMonitoredRegionsCount`.
 Once the monitored regions associated with applets exceeds `Constants.MaxCoreLocationManagerMonitoredRegionsCount`, the service starts monitoring visits the user makes to only monitor the `Constants.MaxCoreLocationManagerMonitoredRegionsCount` closest regions to the user's location.
*/
class RegionsMonitor: NSObject, CLLocationManagerDelegate, LocationMonitor {
    typealias RegionEvent = (CLRegion) -> Void
    typealias RegionErrorEvent = (CLRegion?, Error) -> Void
    
    /// The manager used to monitor regions
    private let locationManager: CLLocationManager
    
    struct Constants {
        /// According to the CoreLocationManager monitoring docs, the system can only monitor a total of 20 regions.
        static let MaxCoreLocationManagerMonitoredRegionsCount = 20
    }
    
    /// Closure that gets called when monitoring begins for a specific region.
    var didStartMonitoringRegion: RegionEvent?
    /// Closure that gets called when the user enters a region.
    var didEnterRegion: RegionEvent?
    /// Closure that gets called when the user exits a region.
    var didExitRegion: RegionEvent?
    /// Closure that gets called when there's an error in monitoring a specific region.
    var monitoringDidFail: RegionErrorEvent?
    
    /// The list of all monitored regions. Updated by the `updateRegions` method.
    private var allMonitoredRegions: [CLRegion]
    
    /// The list of the regions we're monitoring with the system. Updated by the `updateRegions` method.
    private(set) var currentlyMonitoredRegions: Set<CLRegion>
    
    /// Creates an instance of `RegionsMonitor`.
    ///
    /// - Parameters:
    ///     - locationManager: An instance of `CLLocationManager` to use in monitoring regions.
    ///     - allowsBackgroundLocationUpdates: A flag that determines whether or not background location updates should be enabled on the location manager.
    init(locationManager: CLLocationManager = CLLocationManager(),
         allowsBackgroundLocationUpdates: Bool) {
        self.locationManager = locationManager
        self.allMonitoredRegions = []
        self.currentlyMonitoredRegions = .init()

        super.init()
        
        self.locationManager.delegate = self
        if allowsBackgroundLocationUpdates {
            self.locationManager.allowsBackgroundLocationUpdates = true
        }
        self.currentlyMonitoredRegions = locationManager.monitoredRegions
    }
    
    /// Updates the regions that are monitored. Starts core location's visits monitoring if needed.
    ///
    /// - Parameters:
    ///     - regions: The list of regions to monitor.
    func updateRegions(_ regions: [CLRegion]) {
        self.allMonitoredRegions = regions
        if shouldStartVisitsMonitor() {
            if type(of: locationManager).authorizationStatus() == .authorizedAlways {
                locationManager.startMonitoringVisits()
            } else {
                locationManager.stopMonitoringVisits()
            }
        } else if type(of: locationManager).authorizationStatus() == .authorizedAlways {
            startMonitor()
        } else {
            stopMonitor()
        }
    }
    
    /// Determines whether or not significantLocationMonitoring needs to be started or not.
    /// Checks to see what locations are currently being monitored, what locations we need to monitor, and the intersection of these sets.
    /// If the value: count of the currently monitored regions + (count of regions we want to monitor - count of intersection of those sets) > 20 then we return true otherwise we return false
    ///
    /// - returns: A boolean value that determines whether or not we need to start significant location monitoring.
    private func shouldStartVisitsMonitor() -> Bool {
        let monitoredRegionsMapped = allMonitoredRegions.compactMap { $0 as? CLCircularRegion }.map { IFTTTCircularRegion(region: $0) }
        let currentlyMonitoredRegionsMapped = currentlyMonitoredRegions.compactMap { $0 as? CLCircularRegion }.map { IFTTTCircularRegion(region: $0) }
        
        let monitoredRegionsMappedSet = Set(monitoredRegionsMapped)
        
        let intersection = currentlyMonitoredRegionsMapped.intersection(monitoredRegionsMappedSet)
        return (currentlyMonitoredRegionsMapped.count + (monitoredRegionsMappedSet.count - intersection.count)) > Constants.MaxCoreLocationManagerMonitoredRegionsCount
    }
    
    /// Registers the parameter regions with the CLLocationManager. Ensures that we don't monitor a region that's already monitored.
    ///
    /// - Parameters:
    ///     - regions: The list of regions to monitor with the CLLocationManager.
    private func register(regions: [CLRegion]) {
        let regionsToRegisterMapped = regions.compactMap { $0 as? CLCircularRegion }.map { IFTTTCircularRegion(region: $0) }
        let currentlyMonitoredRegionsMapped = currentlyMonitoredRegions.compactMap { $0 as? CLCircularRegion }.map { IFTTTCircularRegion(region: $0) }
        
        let regionsToStopMonitoringMapped = Set(currentlyMonitoredRegionsMapped).subtracting(regionsToRegisterMapped)
        let regionsToStopMonitoring = regionsToStopMonitoringMapped.map { $0.region }
        
        regionsToStopMonitoring.forEach { (region) in
            locationManager.stopMonitoring(for: region)
            ConnectButtonController.synchronizationLog("Did end monitoring for region: \(region)")
        }
        
        regionsToRegisterMapped.forEach { (iftttRegion) in
            if CLLocationManager.isMonitoringAvailable(for: type(of: iftttRegion.region))
                && iftttRegion.region.isIFTTTRegion
                && !currentlyMonitoredRegionsMapped.contains(iftttRegion) {
                locationManager.startMonitoring(for: iftttRegion.region)
            }
        }
        
        self.currentlyMonitoredRegions = Set(regions)
    }
    
    /// Updates the list of registered regions around the parameter visit.
    ///
    /// - Parameters:
    ///     - visit: The visit to use in determining what regions get monitored. Only the 20 closest regions to this visit get monitored.
    private func update(around visit: CLVisit) {
        let coordinate = CLLocationCoordinate2D(latitude: visit.coordinate.latitude,
                                                longitude: visit.coordinate.longitude)
        let topClosest = allMonitoredRegions.closestRegions(to: coordinate,
                                                            count: Constants.MaxCoreLocationManagerMonitoredRegionsCount)
        register(regions: topClosest)
    }
    
    // MARK:- CoreLocationManagerDelegate
    func locationManager(_ manager: CLLocationManager, didStartMonitoringFor region: CLRegion) {
        didStartMonitoringRegion?(region)
    }
    
    func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
        monitoringDidFail?(region, error)
    }
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        didEnterRegion?(region)
    }
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        didExitRegion?(region)
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        updateMonitoring(with: status)
    }
    
    func locationManager(_ manager: CLLocationManager, didVisit visit: CLVisit) {
        update(around: visit)
    }
    
    // MARK:- LocationMonitor
    func stopMonitor() {
        allMonitoredRegions.forEach { (region) in
            locationManager.stopMonitoring(for: region)
            ConnectButtonController.synchronizationLog("Did end monitoring for region: \(region)")
        }
        
        // Stop visits monitoring if necessary
        locationManager.stopMonitoringVisits()
        
        // Clear out the currently monitored regions
        currentlyMonitoredRegions = .init()
    }
    
    func startMonitor() {
        register(regions: allMonitoredRegions)
    }
    
    func updateMonitoring(with status: CLAuthorizationStatus) {
        if status == .authorizedAlways {
            if shouldStartVisitsMonitor() && CLLocationManager.significantLocationChangeMonitoringAvailable() {
                locationManager.startMonitoringSignificantLocationChanges()
            }
            startMonitor()
        } else {
            if CLLocationManager.significantLocationChangeMonitoringAvailable() {
                locationManager.stopMonitoringSignificantLocationChanges()
            }
            stopMonitor()
        }
    }
    
    func reset() {
        // Stop monitoring
        stopMonitor()
    }
   
    deinit {
        locationManager.delegate = nil
    }
}
