//
//  ConnectionsRegistry.swift
//  IFTTT SDK
//
//  Copyright © 2020 IFTTT. All rights reserved.
//

import Foundation

extension Notification.Name {
    /// Describes a notification that gets emitted when the connections registry is updated.
    /// - Notes:
    ///     - The `userInfo` of the notification has the following keys/values:
    ///         - "UpdateConnectionsSetKey": <An array of JSON that maps to `Connection.ConnectionStorage`>
    static let UpdateConnectionsName = Notification.Name("UpdateConnectionsName")
}

/// A struct to transmit connections registry updates
struct ConnectionsRegistryNotification {
    
    /// The key for the set of connections emitted when the connection registry changes.
    static let UpdateConnectionsSetKey = "UpdateConnectionsSetKey"
    
    /// Called when the registry updates its stored set of connections
    ///
    /// - Parameters:
    ///     - connections: The `Set<Connection.ConnectionStorage>` containing `Connection.ConnectionStorage` objects that've changed.
    static func didUpdateConnections(_ connections: Set<Connection.ConnectionStorage>) {
        let notification = Notification(name: .UpdateConnectionsName,
                                        object: nil,
                                        userInfo: [
                                            ConnectionsRegistryNotification.UpdateConnectionsSetKey:
                                                connections.map { $0.toJSON() }
                                        ])
        NotificationCenter.default.post(notification)
    }
}

private extension Dictionary where Key == String, Value == Any {
    /// Returns a set of `Connection.ConnectionStorage` stored in the values of the reciever.
    var connections: Set<Connection.ConnectionStorage> {
        return Set(values.compactMap { $0 as? JSON }
            .compactMap { Connection.ConnectionStorage(json: $0) })
    }
}

extension NSNotification.Name {
    /// Notification that gets emitted whenever one of the user's connection gets updated.
    static let ConnectionUpdatedNotification = NSNotification.Name("ConnectionUpdatedNotification")
    
    /// Notification that gets emitted whenever a new connection gets added to the registry.
    static let ConnectionAddedNotification = NSNotification.Name("ConnectionAddedNotification")
    
    /// Notification that gets emitted whenever a connection gets removed from the registry.
    static let ConnectionRemovedNotification = NSNotification.Name("ConnectionRemovedNotification")
    
    /// Notification that gets emitted whenver all connections get removed from the registroy.
    static let AllConnectionRemovedNotification = NSNotification.Name("AllConnectionRemovedNotification")
}

/// Stores connection information to be able to use in synchronizations.
final class ConnectionsRegistry {
    
    init() {}
    
    /// Adds the connection with identifier. Optionally notifies the `NotificationCenter` if specified.
    ///
    /// - Parameters:
    ///     - identifier: The identifier of the connection to update the registry with.
    ///     - shouldNotify: A boolean that determines whether or not the default `NotificationCenter` should be notified of the update. Defaults to `true`.
    func addConnections(with identifiers: [String], shouldNotify: Bool = true) {
        let storage = identifiers.map { Connection.ConnectionStorage(id: $0,
                                                                     status: .enabled,
                                                                     activeUserTriggers: .init(),
                                                                     allTriggers: .init()) }
        add(storage, shouldNotify: shouldNotify)
    }
    
    /// Removes the connection with identifier. Optionally notifies the `NotificationCenter` if specified.
    ///
    /// - Parameters:
    ///     - identifier: The identifier of the connection to remove from the registry.
    ///     - shouldNotify: A boolean that determines whether or not the default `NotificationCenter` should be notified of the update. Defaults to `true`.
    func removeConnections(with identifiers: [String], shouldNotifiy: Bool = true) {
        remove(identifiers, shouldNotify: shouldNotifiy)
    }
    
    /// Updates the registry with the parameter connection. Optionally notifies the `NotificationCenter` if specified.
    ///
    /// - Parameters:
    ///     - connection: The connection to update the registry with
    ///     - shouldNotify: A boolean that determines whether or not the default `NotificationCenter` should be notified of the update. Defaults to `true`.
    func update(with connection: Connection, shouldNotify: Bool = true) {
        switch connection.status {
        case .disabled, .initial, .unknown:
            remove([connection.id], shouldNotify: shouldNotify)
        case .enabled:
            let storage = Connection.ConnectionStorage(connection: connection)
            add([storage], shouldNotify: shouldNotify)
        }
    }
    
    /// Gets the connections stored in the registry.
    ///
    /// - Returns: A `Set` of all the connections that the user has enabled.
    func getConnections() -> Set<Connection.ConnectionStorage> {
        guard let map = UserDefaults.connections else { return .init() }
        return map.connections
    }
    
    /// Gets the count of user enabled connections stored in the registry.
    ///
    /// - Returns: A count of the user's enabled connections stored in the registry
    func getConnectionsCount() -> Int {
        guard let map = UserDefaults.connections else { return 0 }
        return map.count
    }
    
    /// Adds a connection to the registry.
    ///
    /// - Parameters:
    ///     - connection: The connection to add to the registry.
    private func add(_ connections: [Connection.ConnectionStorage], shouldNotify: Bool) {
        connections.forEach { add($0, shouldNotify: shouldNotify) }
    }
    
    private func add(_ connection: Connection.ConnectionStorage, shouldNotify: Bool) {
        var map = UserDefaults.connections
        var modifiedConnection = connection
        
        let foundConnection = map?.values.first(where: { value -> Bool in
            guard let json = value as? JSON,
                let innerStorage = Connection.ConnectionStorage(json: json) else { return false }
            return innerStorage == connection
        })
        
        if let _foundConnectionJSON = foundConnection as? JSON,
           let _foundConnection = Connection.ConnectionStorage(json: _foundConnectionJSON) {
            modifiedConnection = .init(id: connection.id,
                                       status: connection.status,
                                       activeUserTriggers: connection.activeUserTriggers.count > 0 ? connection.activeUserTriggers: _foundConnection.activeUserTriggers,
                                       allTriggers: connection.allTriggers.count > 0 ? connection.allTriggers: _foundConnection.allTriggers)
        }
        
        let notificationName: Notification.Name = foundConnection != nil ? .ConnectionUpdatedNotification: .ConnectionAddedNotification
        
        let storageJSON = modifiedConnection.toJSON()
        if map != nil {
            map?[connection.id] = storageJSON
        } else {
            map = [connection.id: storageJSON]
        }
        
        UserDefaults.connections = map
        
        if let map = map {
            ConnectionsRegistryNotification.didUpdateConnections(map.connections)
        }
        
        if shouldNotify {
            NotificationCenter.default.post(.init(name: notificationName, object: nil, userInfo: ["connection_id": connection.id]))
        }
    }
    
    /// Removes a connection from the registry.
    ///
    /// - Parameters:
    ///     - id: The connection id to remove from the registry.
    private func remove(_ ids: [String], shouldNotify: Bool) {
        var map = UserDefaults.connections
        ids.forEach {
            guard let val = map?[$0] as? JSON,
                  var connectionStorage = Connection.ConnectionStorage(json: val) else { return }
            connectionStorage.status = .disabled
            map?[$0]? = connectionStorage.toJSON()
        }
        
        if let map = map {
            ConnectionsRegistryNotification.didUpdateConnections(map.connections)
        }
        
        ids.forEach { map?[$0] = nil }
        UserDefaults.connections = map
        
        if shouldNotify {
            NotificationCenter.default.post(name: .ConnectionRemovedNotification, object: nil)
        }
    }
    
    /// Removes all connections from the registry
    ///
    func removeAll(shouldNotify: Bool = true) {
        let keys = UserDefaults.connections?.keys
        keys?.forEach {
            guard let val = UserDefaults.connections?[$0] as? JSON,
                  var connectionStorage = Connection.ConnectionStorage(json: val) else { return }
            connectionStorage.status = .disabled
            UserDefaults.connections?[$0]? = connectionStorage.toJSON()
        }
        
        ConnectionsRegistryNotification.didUpdateConnections(UserDefaults.connections?.connections ?? .init())
        UserDefaults.connections = nil
        
        if shouldNotify {
            NotificationCenter.default.post(name: .AllConnectionRemovedNotification, object: nil)
        }
    }
}
