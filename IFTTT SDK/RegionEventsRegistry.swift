//
//  RegionEventsRegistry.swift
//  IFTTT SDK
//
//  Copyright © 2020 IFTTT. All rights reserved.
//

import Foundation

struct APIDateFormatter {
    static let satellite: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        f.timeZone = TimeZone(secondsFromGMT: 0)
        return f
    }()
}

/// Stores region events information to be able to use in synchronizations.
final class RegionEventsRegistry {
    /// Gets all the region events stored in the registry.
    func getRegionEvents() -> [RegionEvent] {
        guard let array = StorageHelpers.regionEvents else { return [] }
        return array.compactMap { $0 as? JSON }.compactMap { RegionEvent(json: $0) }
    }
    
    /// Adds a region event to the registry.
    ///
    /// - Parameters:
    ///     - event: The event to add to the registry.
    func add(_ event: RegionEvent) {
        var array = StorageHelpers.regionEvents

        let storage = event.toJSON(stripPrefix: false)
        if array != nil {
            array?.append(storage)
        } else {
            array = [storage]
        }
        
        StorageHelpers.regionEvents = array
    }
    
    /// Removes an array of region events from the registry.
    ///
    /// - Parameters:
    ///     - events: The events to remove from the registry.
    func remove(_ events: [RegionEvent]) {
        var array = StorageHelpers.regionEvents
        array?.removeAll(where: { (value) -> Bool in
            guard let eventJSON = value as? JSON,
                let event = RegionEvent(json: eventJSON) else { return false }
            return events.contains {
                $0.triggerSubscriptionId == event.triggerSubscriptionId &&
                $0.recordId == event.recordId
            }
        })
        
        StorageHelpers.regionEvents = array
    }
    
    /// Removes all region events from the registry.
    func removeAll() {
        StorageHelpers.regionEvents = nil
    }
}
