//
//  RegionEvent.swift
//  IFTTTConnectSDK
//
//  Copyright © 2021 IFTTT. All rights reserved.
//

import Foundation

/// A record of a region entry/exit event that occurs in the SDK.
public struct RegionEvent: Hashable {
    private struct Key {
        static let RecordId = "record_id"
        static let RegionType = "region_type"
        static let OccurredAt = "occurred_at"
        static let EventType = "event_type"
        static let ChannelId = "channel_id"
        static let TriggerSubscriptionId = "trigger_subscription_id"
        static let InstallationId = "installation_id"
    }
    
    private struct Constants {
        static let Geo = "geo"
        static let LocationServiceId = 941030000.description
    }
    
    /// The kind of event this is.
    public let kind: RegionEventKind
    
    /// The id of the event.
    let recordId: UUID
    
    /// The timestamp this event occurred at.
    let occurredAt: Date
    
    /// The trigger subscription id that this event corresponds to.
    let triggerSubscriptionId: String
    
    /// Creates an instance of `RegionEvent`.
    ///
    /// - Parameters:
    ///     - recordId: The id of the recorded event.
    ///     - kind: The kind of region event.
    ///     - ocurredAt: The timestamp this event occurred at.
    ///     - triggerSubscriptionId: The trigger subscription id that this event corresponds to.
    init(recordId: UUID = UUID(),
         kind: RegionEventKind,
         occurredAt: Date = Date(),
         triggerSubscriptionId: String) {
        self.recordId = recordId
        self.kind = kind
        self.occurredAt = occurredAt
        self.triggerSubscriptionId = triggerSubscriptionId
    }
    
    /// Creates an optional instance of `RegionEvent`.
    ///
    /// - Parameters:
    ///     - json: The `JSON` that should be used in creating the `RegionEvent`
    init?(json: JSON) {
        let parser = Parser(content: json)
        guard let recordId = parser[Key.RecordId].uuid,
            let ocurredAtString = parser[Key.OccurredAt].string,
            let ocurredAtDate = APIDateFormatter.satellite.date(from: ocurredAtString),
            let eventType = parser[Key.EventType].representation(of: RegionEventKind.self),
            let triggerSubscriptionId = parser[Key.TriggerSubscriptionId].string else {
                return nil
        }
        self.recordId = recordId
        self.occurredAt = ocurredAtDate
        self.kind = eventType
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
}
