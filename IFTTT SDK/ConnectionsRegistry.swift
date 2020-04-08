//
//  ConnectionsRegistry.swift
//  IFTTT SDK
//
//  Copyright © 2020 IFTTT. All rights reserved.
//

import Foundation

/// Stores connection information to be able to use in synchronizations.
final class ConnectionsRegistry {
    /// The shared instance that should be used in creating an instance of the registry.
    static let shared = ConnectionsRegistry()
    
    /// Stores constants used in this class.
    private struct Constants {
        /// The `UserDefaults` key used to store connection information.
        static let ConnectionsUserDefaultKey = "ConnectionsRegistry.ConnectionsUserDefaultKey"
    }
    
    private init() {}
    
    /// Updates the registry with the parameter connection. Optionally notifies the `NotificationCenter` if specified.
    ///
    /// - Parameters:
    ///     - connection: The connection to update the registry with
    ///     - shouldNotify: A boolean that determines whether or not the default `NotificationCenter` should be notified of the update.
    func update(with connection: Connection, shouldNotify: Bool = true) {
        switch connection.status {
        case .disabled, .initial, .unknown:
            remove(connection.id)
        case .enabled:
            add(connection.id)
        }
        
        if shouldNotify {
            NotificationCenter.default.post(name: .ConnectionsChangedNotification, object: nil)
        }
    }
    
    /// Gets the connections stored in the registry.
    func getConnections() -> Set<String> {
        guard let array = UserDefaults.standard.stringArray(forKey: Constants.ConnectionsUserDefaultKey) else { return .init() }
        return Set(array)
    }
    
    /// Adds a connection to the registry.
    ///
    /// - Parameters:
    ///     - connectionId: The id of the connection to add to the registry.
    private func add(_ connectionId: String) {
        var array = UserDefaults.standard.stringArray(forKey: Constants.ConnectionsUserDefaultKey)
        defer {
            UserDefaults.standard.set(array, forKey: Constants.ConnectionsUserDefaultKey)
        }
        if array != nil {
            array?.append(connectionId)
        } else {
            array = [connectionId]
        }
    }
    
    /// Removes a connection from the registry.
    ///
    /// - Parameters:
    ///     - connectionId: The id of the connection to remove from the registry.
    private func remove(_ connectionId: String) {
        var array = UserDefaults.standard.stringArray(forKey: Constants.ConnectionsUserDefaultKey)
        defer {
            UserDefaults.standard.set(array, forKey: Constants.ConnectionsUserDefaultKey)
        }
        if array != nil {
            array?.removeAll(where: { $0 == connectionId })
        }
    }
}
