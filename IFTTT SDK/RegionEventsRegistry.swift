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

struct RegionEvent: Hashable {
    private struct Key {
        static let RecordId = "record_id"
        static let RegionType = "region_type"
        static let OccurredAt = "ocurred_at"
        static let EventType = "event_type"
        static let ChannelId = "channel_id"
        static let TriggerSubscriptionId = "trigger_subscription_id"
        static let InstallationId = "installation_id"
    }
    
    private struct Constants {
        static let Geo = "geo"
        static let LocationServiceId = 941030000.description
    }
    
    enum Kind: String {
        case entry = "entry"
        case exit = "exit"
    }
    
    let recordId: UUID
    let kind: Kind
    let occurredAt: Date
    let triggerSubscriptionId: String
    
    init(recordId: UUID = UUID(),
         kind: Kind,
         occurredAt: Date = Date(),
         triggerSubscriptionId: String) {
        self.recordId = recordId
        self.kind = kind
        self.occurredAt = occurredAt
        self.triggerSubscriptionId = triggerSubscriptionId
    }
    
    func toJSON(stripPrefix: Bool) -> JSON {
        return [
            Key.RecordId: recordId.uuidString,
            Key.RegionType: Constants.Geo,
            Key.OccurredAt: APIDateFormatter.satellite.string(from: occurredAt),
            Key.EventType: kind.rawValue,
            Key.ChannelId: Constants.LocationServiceId,
            Key.TriggerSubscriptionId: stripPrefix ? triggerSubscriptionId.stripIFTTTPrefix(): triggerSubscriptionId,
            Key.InstallationId: API.anonymousId
        ]
    }
    
    init?(json: JSON) {
        let parser = Parser(content: json)
        guard let recordId = parser[Key.RecordId].uuid,
            let ocurredAtString = parser[Key.OccurredAt].string,
            let ocurredAtDate = APIDateFormatter.satellite.date(from: ocurredAtString),
            let eventType = parser[Key.EventType].representation(of: Kind.self),
            let triggerSubscriptionId = parser[Key.TriggerSubscriptionId].string else {
                return nil
        }
        self.recordId = recordId
        self.occurredAt = ocurredAtDate
        self.kind = eventType
        self.triggerSubscriptionId = triggerSubscriptionId
    }
    
}

/// Stores region events information to be able to use in synchronizations.
final class RegionEventsRegistry {
    /// Gets all the region events stored in the registry.
    func getRegionEvents() -> [RegionEvent] {
        guard let array = UserDefaults.regionEvents else { return [] }
        return array.compactMap { $0 as? JSON }.compactMap { RegionEvent(json: $0) }
    }
    
    /// Adds a region event to the registry.
    ///
    /// - Parameters:
    ///     - event: The event to add to the registry.
    func add(_ event: RegionEvent) {
        var array = UserDefaults.regionEvents

        let storage = event.toJSON(stripPrefix: false)
        if array != nil {
            array?.append(storage)
        } else {
            array = [storage]
        }
        
        UserDefaults.regionEvents = array
    }
    
    /// Removes an array of region events from the registry.
    ///
    /// - Parameters:
    ///     - events: The events to remove from the registry.
    func remove(_ events: [RegionEvent]) {
        var array = UserDefaults.regionEvents
        array?.removeAll(where: { (value) -> Bool in
            guard let eventJSON = value as? JSON,
                let event = RegionEvent(json: eventJSON) else { return false }
            return events.contains(event)
        })
        
        UserDefaults.regionEvents = array
    }
    
    /// Removes all region events from the registry.
    func removeAll() {
        UserDefaults.regionEvents = nil
    }
}
