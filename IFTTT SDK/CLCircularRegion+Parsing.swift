//
//  CLCircularRegion+Parsing.swift
//  IFTTT SDK
//
//  Copyright © 2020 IFTTT. All rights reserved.
//

import Foundation
import CoreLocation

struct Constants {
    static let IFTTTRegionPrefix = "ifttt"
}

extension CLRegion {
    /// Determines whether or not the region is an region associated with an IFTTT connection.
    var isIFTTTRegion: Bool {
        return identifier.lowercased().starts(with: Constants.IFTTTRegionPrefix)
    }
}

extension CLCircularRegion {
    private static let locationManager = CLLocationManager()
    
    convenience init?(json: JSON, triggerId: String) {
        let parser = Parser(content: json)
        let locationParser = parser["value"]

        guard let latitude = locationParser["lat"].double,
            let longitude = locationParser["lng"].double,
            var radius = locationParser["radius"].double else {
                return nil
        }
        
        radius = min(radius, CLCircularRegion.locationManager.maximumRegionMonitoringDistance)
        
        let center = CLLocationCoordinate2D(latitude: latitude as CLLocationDegrees, longitude: longitude as CLLocationDegrees)
        let identifier = CLCircularRegion.generateIFTTTRegionIdentifier(from: triggerId)
        
        self.init(center: center,
                  radius: radius as CLLocationDistance,
                  identifier: identifier)
    }
    
    private static func generateIFTTTRegionIdentifier(from originalIdentifier: String) -> String {
        return "\(Constants.IFTTTRegionPrefix)_\(originalIdentifier)"
    }
}

