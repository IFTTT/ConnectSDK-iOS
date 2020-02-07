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
    var identifier: String? { get }
    
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
        return "sdk"
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

/// An implementation of `AnalyticsTrackable` that corresponds to any context that is to be sent on a analytics event.
struct AnalyticsObject: AnalyticsTrackable {
    let identifier: String?
    let type: String
    let attributes: AnalyticsData?
    
    static let worksWithIFTTT = AnalyticsObject(identifier: "button", type: "works_with_ifttt", attributes: nil)
    
    static let email = AnalyticsObject(identifier: nil, type: "connection_email", attributes: nil)
    
    static let about = AnalyticsObject(identifier: "connect_information", type: "modal", attributes: nil)
    
    static let privacyPolicy = AnalyticsObject(identifier: "privacy_policy", type: "button", attributes: nil)
    
    static func button(identifier: String?) -> AnalyticsObject {
        return AnalyticsObject(identifier: identifier, type: "button", attributes: nil)
    }
}

extension Location {
    /// The `Location` for the connect button impression analytics event
    ///
    /// - Returns: The `Location` that corresponds to this analytics event.
    static var connectButtonImpression: Location {
        var locationIdentifier: String? = nil
        if let appName = Bundle.main.appName {
           locationIdentifier = "\(appName)"
        }
        return Location(type: "connect_button", identifier: locationIdentifier)
    }
    
    /// The `Location` for the connect button connection analytics event
    ///
    /// - Returns: The `Location` that corresponds to this analytics event.
    static func connectButtonLocation(_ connection: Connection?) -> Location? {
        guard let connection = connection else { return nil }
        
        return Location(type: "connect_button", identifier: connection.id)
    }
}
