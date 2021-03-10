//
//  Array+Helpers.swift
//  IFTTT SDK
//
//  Copyright © 2020 IFTTT. All rights reserved.
//

import Foundation
import CoreLocation

extension Array where Element: CLRegion {
    /// Determines the regions to return closest to the parameter coordinates. Only returns the top `count` locations.
    ///
    /// - Parameters:
    ///     - coordinates: The coordinates of the location to use in determining the regions to be returned.
    ///     - count: The amount of regions to return.
    /// - Returns: The `count` closest regions to the parameter location.
    func closestRegions(to coordinates: CLLocationCoordinate2D, count: Int) -> [CLRegion] {
        let location = CLLocation(latitude: coordinates.latitude,
                                  longitude: coordinates.longitude)
        let regionsClosestToLocation = compactMap { $0 as? CLCircularRegion }
            .sorted { (region1, region2) -> Bool in
                let region1Location = CLLocation(latitude: region1.center.latitude, longitude: region1.center.longitude)
                let region2Location = CLLocation(latitude: region2.center.latitude, longitude: region2.center.longitude)
                return location.distance(from: region1Location) < location.distance(from: region2Location)
            }
        let topClosest = regionsClosestToLocation.keepFirst(count)
        return topClosest
    }
}

extension Array {
    func keepFirst(_ n: Int) -> Array {
        let slice = prefix(n)
        return Array(slice)
    }
}
