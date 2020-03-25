//
//  ConnectionsMonitor.swift
//  IFTTT SDK
//
//  Copyright © 2020 IFTTT. All rights reserved.
//

import Foundation
import CoreLocation

/// A protocol that allows for subscribers to process updates for the user's connections.
protocol ConnectionMonitorSubscriber {
    /// A hook for a native service to be able to update itself based on the connection update.
    ///
    /// - Parameters:
    ///     - connection: The updated `Connection` object.
    func processUpdate(with connection: Connection)
}

/// Monitors connections to update native services.
public class ConnectionsMonitor {
    /// Instance used to start/stop monitoring.
    public static let shared = ConnectionsMonitor()
    
    /// A list of subscribers to update when a connection gets updated
    private let subscribers: [ConnectionMonitorSubscriber]
    
    /// Creates an instance of `ConnectionsMonitor`
    ///
    /// - Returns: An initialized instance of `ConnectionsMonitor`.
    private init() {
        let location = LocationService(allowsBackgroundLocationUpdates: Bundle.main.backgroundLocationEnabled)
        self.subscribers = [location]
    }
    
    /// Updates subscribers with this connection.
    ///
    /// - Parameters:
    ///     - connection: The connection to run updates for
    func update(with connection: Connection) {
        subscribers.forEach { $0.processUpdate(with: connection) }
    }
}
