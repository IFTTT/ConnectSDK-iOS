//
//  NativeServices.swift
//  IFTTT SDK
//
//  Copyright © 2020 IFTTT. All rights reserved.
//

import Foundation
import CoreLocation

/// Enumerates supported native service triggers
enum Trigger: Equatable, Hashable, CaseIterable {
    static var allCases: [Trigger] {
        return [
            .location(region: .init())
        ]
    }
    
    private struct Constants {
        static let LocationIdentifer = "location"
    }
    
    /// Describes a location trigger. Currently only region exit and/or entry are supported.
    ///
    /// - Parameters:
    ///     - region: A `CLCircularRegion` that corresponds to the region to monitor.
    case location(region: CLCircularRegion)

    /// Uniquely identifies this trigger.
    var identifier: String {
        switch self {
        case .location:
            return Constants.LocationIdentifer
        }
    }
    
    /// Creates an instance of `Trigger`
    ///
    /// - Parameters:
    ///     - json: The `JSON` object corresponding to the trigger
    ///     - triggerId: A value that uniquely identifies this trigger. Used in registering multiple unique triggers with the system.
    init?(json: JSON, triggerId: String) {
        guard let fieldId = json["field_id"] as? String else { return nil }
        
        switch fieldId {
        case Constants.LocationIdentifer:
            guard let region = CLCircularRegion(json: json, triggerId: triggerId) else { return nil }
            self = .location(region: region)
        default:
            return nil
        }
    }
 
    func hash(into hasher: inout Hasher) {
        hasher.combine(identifier)
    }
    
    static func ==(lhs: Trigger, rhs: Trigger) -> Bool {
        return lhs.identifier == rhs.identifier
    }
}

/// Enumerates permissions to be requested from the user. Determined by the triggers for a Connection.
enum NativePermission: CaseIterable, Equatable {
    
    /// Describes an always required location permission.
    case location
}

func ==(lhs: NativePermission, rhs: NativePermission) -> Bool {
    switch (lhs, rhs) {
    case (.location, .location):
        return true
    }
}

