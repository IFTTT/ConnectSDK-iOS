//
//  ConnectionsRegistry.swift
//  IFTTT SDK
//
//  Copyright © 2020 IFTTT. All rights reserved.
//

import Foundation

extension NSNotification.Name {
    /// Notification that gets emitted whenever one of the user's connection gets updated.
    static let ConnectionUpdatedNotification = NSNotification.Name("ConnectionUpdatedNotification")
    
    /// Notification that gets emitted whenever a new connection gets added to the registry.
    static let ConnectionAddedNotification = NSNotification.Name("ConnectionAddedNotification")
    
    /// Notification that gets emitted whenever a connection gets removed from the registry.
    static let ConnectionRemovedNotification = NSNotification.Name("ConnectionRemovedNotification")
}

/// Stores connection information to be able to use in synchronizations.
final class ConnectionsRegistry {
    
    init() {}
    
    /// Updates the registry with the parameter connection. Optionally notifies the `NotificationCenter` if specified.
    ///
    /// - Parameters:
    ///     - connection: The connection to update the registry with
    ///     - shouldNotify: A boolean that determines whether or not the default `NotificationCenter` should be notified of the update. Defaults to `true`.
    func update(with connection: Connection, shouldNotify: Bool = true) {
        switch connection.status {
        case .disabled, .initial, .unknown:
            remove(connection, shouldNotify: shouldNotify)
        case .enabled:
            add(connection, shouldNotify: shouldNotify)
        }
    }
    
    /// Gets the connections stored in the registry.
    func getConnections() -> Set<Connection.ConnectionStorage> {
        guard let map = UserDefaults.connections else { return .init() }
        let connections = map.values.compactMap { $0 as? JSON }.compactMap { Connection.ConnectionStorage(json: $0) }
        return Set(connections)
    }
    
    /// Adds a connection to the registry.
    ///
    /// - Parameters:
    ///     - connection: The connection to add to the registry.
    private func add(_ connection: Connection, shouldNotify: Bool) {
        var map = UserDefaults.connections
        let storage = Connection.ConnectionStorage(connection: connection)
        let storageJSON = storage.toJSON()
        
        let containsConnection = map?.values.contains(where: { value -> Bool in
            guard let json = value as? JSON,
                let innerStorage = Connection.ConnectionStorage(json: json) else { return false }
            return innerStorage == storage
        }) ?? false
        
        let notificationName: Notification.Name = containsConnection ? .ConnectionUpdatedNotification: .ConnectionAddedNotification
        
        if map != nil {
            map?[connection.id] = storageJSON
        } else {
            map = [connection.id: storageJSON]
        }
        
        UserDefaults.connections = map
        
        if shouldNotify {
            NotificationCenter.default.post(name: notificationName, object: nil)
        }
    }
    
    /// Removes a connection from the registry.
    ///
    /// - Parameters:
    ///     - connection: The connection to remove from the registry.
    private func remove(_ connection: Connection, shouldNotify: Bool) {
        var map = UserDefaults.connections
        map?[connection.id] = nil
        UserDefaults.connections = map
        
        if shouldNotify {
            NotificationCenter.default.post(name: .ConnectionRemovedNotification, object: nil)
        }
    }
}
