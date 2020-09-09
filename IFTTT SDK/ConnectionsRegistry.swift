//
//  ConnectionsRegistry.swift
//  IFTTT SDK
//
//  Copyright © 2020 IFTTT. All rights reserved.
//

import Foundation

extension NSNotification.Name {
    /// Notification that gets emitted whenever the user's connections change.
    static let ConnectionsChangedNotification = NSNotification.Name("ConnectionsChangedNotification")
}

/// Stores connection information to be able to use in synchronizations.
final class ConnectionsRegistry {
    /// Stores constants used in this class.
    private struct Constants {
        /// The `UserDefaults` key used to store connection information.
        static let ConnectionsUserDefaultKey = "ConnectionsRegistry.ConnectionsUserDefaultKey"
    }
    
    init() {}
    
    /// Updates the registry with the parameter connection. Optionally notifies the `NotificationCenter` if specified.
    ///
    /// - Parameters:
    ///     - connection: The connection to update the registry with
    ///     - shouldNotify: A boolean that determines whether or not the default `NotificationCenter` should be notified of the update.
    func update(with connection: Connection, shouldNotify: Bool = true) {
        switch connection.status {
        case .disabled, .initial, .unknown:
            remove(connection)
        case .enabled:
            add(connection)
        }
        
        if shouldNotify {
            NotificationCenter.default.post(name: .ConnectionsChangedNotification, object: nil)
        }
    }
    
    /// Gets the connections stored in the registry.
    func getConnections() -> Set<Connection.ConnectionStorage> {
        guard let map = UserDefaults.standard.dictionary(forKey: Constants.ConnectionsUserDefaultKey) else { return .init() }
        let connections = map.values.compactMap { $0 as? JSON }.compactMap { Connection.ConnectionStorage(json: $0) }
        return Set(connections)
    }
    
    /// Adds a connection to the registry.
    ///
    /// - Parameters:
    ///     - connection: The connection to add to the registry.
    private func add(_ connection: Connection) {
        var map = UserDefaults.standard.dictionary(forKey: Constants.ConnectionsUserDefaultKey)
        defer {
            UserDefaults.standard.set(map, forKey: Constants.ConnectionsUserDefaultKey)
        }
        let storage = Connection.ConnectionStorage(connection: connection).toJSON()
        if map != nil {
            map?[connection.id] = storage
        } else {
            map = [connection.id: storage]
        }
    }
    
    /// Removes a connection from the registry.
    ///
    /// - Parameters:
    ///     - connection: The connection to remove from the registry.
    private func remove(_ connection: Connection) {
        var map = UserDefaults.standard.dictionary(forKey: Constants.ConnectionsUserDefaultKey)
        defer {
            UserDefaults.standard.set(map, forKey: Constants.ConnectionsUserDefaultKey)
        }
        map?[connection.id] = nil
    }
}