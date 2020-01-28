//
//  Analytics+DataStructures.swift
//  IFTTT SDK
//
//  Copyright © 2020 IFTTT. All rights reserved.
//

import Foundation

/// Represents an object that can be tracked.
protocol AnalyticsTrackable {
    /// The type of this object
    var type: String { get }
    
    /// The id for this object
    var id: String? { get }
    
    /// An optional `AnalyticsData` that corresponds to any extra fields that should be tracked for this object.
    var attributes: AnalyticsData? { get }
}

/// Represents and analytics event.
protocol AnalyticsEventRepresentable {
    /// The key for this event
    var name: String { get }
    
    /// Any prefix that's attached to the event name
    var prefix: String? { get }
    
    /// The delimiter between the prefix and the name
    var delimiter: String? { get }
}

extension AnalyticsEventRepresentable where Self : RawRepresentable, Self.RawValue == String {
    var name: String {
        guard let prefix = prefix,
            let delimiter = delimiter else {
            return rawValue
        }
        return [prefix, rawValue].joined(separator: delimiter)
    }
}

/// Enumerates all of the analytics states.
enum AnalyticsState: String {
    case Created = "created"
    case SignedIn = "signed_in"
    case Connected = "connected"
    case Updated = "updated"
    case Enabled = "enabled"
    case Disabled = "disabled"
    case Deleted = "deleted"
    case ServicesChecked = "services_checked"
    case ConfigurationChecked = "config_checked"
    case Verified = "verified"
}

/// Represents an analytics event.
enum AnalyticsEvent: String, AnalyticsEventRepresentable {
    var prefix: String? {
        return "ios"
    }
       
    var delimiter: String? {
        return "."
    }
    
    case PageView = "pageviewed"
    case StateChange = "statechange"
    case Click = "click"
    case Impression = "impression"
}

/// Represents an analytics location.
struct Location {
    let type: String?
    let identifier: String?
    
    init(type: String? = nil, identifier: String? = nil) {
        self.type = type
        self.identifier = identifier
    }
}

extension UIApplication.State {
    /// Returns an string that represents the Analytics description for the application's state.
    var analyticsDescription: String {
        switch self {
        case .active: return "foreground"
        case .background: return "background"
        case .inactive: return "inactive"
        @unknown default: return "unknown"
        }
    }
}
