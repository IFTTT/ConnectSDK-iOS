//
//  NativeServices.swift
//  IFTTT SDK
//
//  Copyright © 2020 IFTTT. All rights reserved.
//

import Foundation
import CoreLocation

/// Enumerates supported native service triggers
public enum Trigger: Hashable {
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
        case .location(let region):
            return region.identifier
        }
    }
    
    /// Creates an instance of `Trigger`
    ///
    /// - Parameters:
    ///     - json: The `JSON` object corresponding to the trigger
    ///     - triggerId: A value that uniquely identifies this trigger. Used in registering multiple unique triggers with the system.
    init?(json: JSON, triggerId: String) {
        guard let fieldId = json["field_id"] as? String else {
            return nil
        }
        
        switch fieldId {
        case Constants.LocationIdentifer:
            guard let region = CLCircularRegion(json: json, triggerId: triggerId) else {
                return nil
            }
            self = .location(region: region)
        default:
            return nil
        }
    }
    
    /// Creates an instance of `Trigger` with default fields from connection
    ///
    /// - Parameters:
    ///     - defaultFieldParser: The default field `Parser` object corresponding to the trigger.
    ///     - triggerId: A value that uniquely identifies this trigger. Used in registering multiple unique triggers with the system.
    init?(defaultFieldParser: Parser, triggerId: String) {
        guard let fieldId = defaultFieldParser["id"].string else {
            return nil
        }
        
        switch fieldId {
        case Constants.LocationIdentifer:
            guard let region = CLCircularRegion(defaultFieldParser: defaultFieldParser, triggerId: triggerId) else {
                return nil
            }
            self = .location(region: region)
        default:
            return nil
        }
    }
    
    /// Creates an instance of `Trigger` from storage. Either from `UserDefaults` or `KeyChain`
    ///
    /// - Parameters:
    ///     - parser: The parser corresponding to the JSON from storage.
    init?(parser: Parser) {
        let locationParser = parser[Constants.LocationIdentifer]
        if let region = CLCircularRegion(parser: locationParser) {
            self = .location(region: region)
            return
        }
        return nil
    }
    
    func toJSON() -> JSON {
        switch self {
        case .location(let region):
            return [
                Constants.LocationIdentifer: region.toUserDefaultsJSON()
            ]
        }
    }
    
    static func supportedTriggerId(_ triggerId: String) -> Bool {
        switch triggerId {
        case Constants.LocationIdentifer: return true
        default: return false
        }
    }
 
    public func hash(into hasher: inout Hasher) {
        hasher.combine(identifier)
    }
    
    public static func ==(lhs: Trigger, rhs: Trigger) -> Bool {
        return lhs.identifier == rhs.identifier
    }
}
