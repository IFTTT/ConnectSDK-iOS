//
//  RegionsMonitor.swift
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
class RegionsMonitor: NSObject, CLLocationManagerDelegate, LocationMonitor {
    typealias RegionEvent = (CLRegion) -> Void
    /// The manager used to monitor regions
    private let locationManager = CLLocationManager()
    /// The monitor used to monitor visits. Used if the number of regions we want to monitor is > 20.
    private let visitsMonitor: VisitsMonitor
    
    private struct Constants {
        /// According to the CoreLocationManager monitoring docs, the system can only monitor a total of 20 regions.
        static let MaxCoreLocationManagerMonitoredRegionsCount = 20
    }
    
    /// Closure that gets called when monitoring begins for a specific region.
    var didStartMonitoringRegion: RegionEvent?
    /// Closure that gets called when the user enters a region.
    var didEnterRegion: RegionEvent?
    /// Closure that gets called when the user exits a region.
    var didExitRegion: RegionEvent?
    
    /// The list of all monitored regions. Updated by the `updateRegions` method.
    private var allMonitoredRegions: Set<CLRegion>
    
    /// Creates an instance of `RegionsMonitor`.
    init(allowsBackgroundLocationUpdates: Bool) {
        self.allMonitoredRegions = []
        self.visitsMonitor = VisitsMonitor(allowsBackgroundLocationUpdates: allowsBackgroundLocationUpdates)

        super.init()
        locationManager.delegate = self
        if allowsBackgroundLocationUpdates {
            locationManager.allowsBackgroundLocationUpdates = true
        }
        visitsMonitor.onVisit = { [weak self] visit in
            guard let self = self else { return }
            self.update(around: visit)
        }
    }
    
    /// Updates the regions that are monitored. Starts `significantLocationMonitor` if needed.
    ///
    /// - Parameters:
    ///     - regions: The list of regions to monitor.
    func updateRegions(_ regions: Set<CLRegion>) {
        self.allMonitoredRegions = regions
        updateMonitoring(with: CLLocationManager.authorizationStatus())
    }
    
    /// Determines whether or not significantLocationMonitoring needs to be started or not.
    /// Checks to see what locations are currently being monitored, what locations we need to monitor, and the intersection of these sets.
    /// If the value: count of the currently monitored regions + (count of regions we want to monitor - count of intersection of those sets) > 20 then we return true otherwise we return false
    ///
    /// - returns: A boolean value that determines whether or not we need to start significant location monitoring.
    private func shouldStartVisitsMonitor() -> Bool {
        let currentlyMonitoredRegions = locationManager.monitoredRegions
        let monitoredRegionsSet = Set(allMonitoredRegions)
        
        let intersection = currentlyMonitoredRegions.intersection(monitoredRegionsSet)
        return (currentlyMonitoredRegions.count + (monitoredRegionsSet.count - intersection.count)) > Constants.MaxCoreLocationManagerMonitoredRegionsCount
    }
    
    /// Registers the parameter regions with the CLLocationManager. Ensures that we don't monitor a region that's already monitored.
    ///
    /// - Parameters:
    ///     - regions: The list of regions to monitor with the CLLocationManager.
    private func register(regions: Set<CLRegion>) {
        let monitoredRegions = locationManager.monitoredRegions
        // Go through the new regions we got passed in and start monitoring those regions if they're not being monitored
        regions.forEach { (region) in
            if !monitoredRegions.contains(region) && CLLocationManager.isMonitoringAvailable(for: type(of: region)) {
                locationManager.startMonitoring(for: region)
            }
        }
        
        // Go through the currently monitored regions of the location manager and check what regions we don't need to monitor anymore
        monitoredRegions.forEach { (region) in
            if region.isIFTTTRegion && !regions.contains(region) {
                locationManager.stopMonitoring(for: region)
            }
        }
    }
    
    /// Updates the list of registered regions around the parameter location.
    ///
    /// - Parameters:
    ///     - location: The location to use in determining what regions get monitored. Only the 20 closest regions to this location get monitored.
    private func update(around visit: CLVisit) {
        let visitLocation = CLLocation(latitude: visit.coordinate.latitude, longitude: visit.coordinate.longitude)
        let regionsClosestToLocation = allMonitoredRegions.compactMap { $0 as? CLCircularRegion }
            .sorted { (region1, region2) -> Bool in
                let region1Location = CLLocation(latitude: region1.center.latitude, longitude: region1.center.longitude)
                let region2Location = CLLocation(latitude: region2.center.latitude, longitude: region2.center.longitude)
                return visitLocation.distance(from: region1Location) < visitLocation.distance(from: region2Location)
            }
        let topClosest = regionsClosestToLocation[..<Constants.MaxCoreLocationManagerMonitoredRegionsCount]

        register(regions: Set(topClosest))
    }
    
    // MARK:- CoreLocationManagerDelegate
    func locationManager(_ manager: CLLocationManager, didStartMonitoringFor region: CLRegion) {
        didStartMonitoringRegion?(region)
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
    
    // MARK:- LocationMonitor
    func stopMonitor() {
        allMonitoredRegions.forEach { (region) in
            if CLLocationManager.isMonitoringAvailable(for: type(of: region)) {
                locationManager.stopMonitoring(for: region)
            }
        }
    }
    
    func startMonitor() {
        register(regions: allMonitoredRegions)
    }
    
    func updateMonitoring(with status: CLAuthorizationStatus) {
        if status == .authorizedAlways || status == .authorizedWhenInUse {
            if shouldStartVisitsMonitor() {
                visitsMonitor.startMonitor()
            } else {
                startMonitor()
            }
        } else {
            visitsMonitor.stopMonitor()
            stopMonitor()
        }
    }
   
    deinit {
        locationManager.delegate = nil
    }
}
