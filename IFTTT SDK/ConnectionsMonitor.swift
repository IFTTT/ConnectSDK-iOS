//
//  ConnectionsMonitor.swift
//  IFTTT SDK
//
//  Copyright © 2020 IFTTT. All rights reserved.
//

import Foundation
import CoreLocation

struct UserAuthenticatedRequestCredentialProvider: ConnectionCredentialProvider {
    var inviteCode: String? { return Keychain.getValue(for: Keychain.Key.InviteCode.rawValue) }
    var userToken: String? { return Keychain.getValue(for: Keychain.Key.UserToken.rawValue) }
    
    /// This isn't used in the network request.
    var oauthCode: String = ""
}


/// A protocol that allows for subscribers to process updates for the user's connections.
protocol ConnectionMonitorSubscriber {
    /// A hook for a native service to be able to update itself based on the user's connections.
    ///
    /// - Parameters:
    ///     - connections: The updated set of `Connection.ConnectionStorage`.
    func processUpdate(with connections: Set<Connection.ConnectionStorage>)
}

/// Monitors connections to update native services.
class ConnectionsMonitor: SynchronizationSubscriber {
    
    /// A list of subscribers to update when a connection gets updated
    private let subscribers: [ConnectionMonitorSubscriber]
    
    /// The registry of connections the user has currently enabled.
    private let connectionsRegistry: ConnectionsRegistry 
    
    /// Network controller to use in making requests
    private let networkController = ConnectionNetworkController()
    
    /// The operation queue to handle synchronization of multiple network requests
    private let operationQueue = OperationQueue()
    
    /// Creates an instance of `ConnectionsMonitor`
    ///
    /// - Parameters:
    ///     - location: An instance of `LocationService` to use when the user's connections get updated.
    ///     - permissionsRequestor: An instance of `PermissionsRequestor` to use when the user's connections get updated
    ///     - connectionsRegistry: The registry of connections that should be monitored.
    /// - Returns: An initialized instance of `ConnectionsMonitor`.
    init(location: LocationService, permissionsRequestor: PermissionsRequestor, connectionsRegistry: ConnectionsRegistry) {
        self.subscribers = [
            permissionsRequestor,
            location
        ]
        self.connectionsRegistry = connectionsRegistry
    }
    
    /// Updates subscribers with this connection.
    ///
    /// - Parameters:
    ///     - connection: The connection to run updates for
    private func update(with connections: Set<Connection.ConnectionStorage>) {
        subscribers.forEach { $0.processUpdate(with: connections) }
    }
    
    // MARK: - SynchronizationSubscriber
    var name: String {
        return "ConnectionsMonitor"
    }
    
    func shouldParticipateInSynchronization(source: SynchronizationSource) -> Bool {
        let credentialProvider = UserAuthenticatedRequestCredentialProvider()
        return !connectionsRegistry.getConnections().isEmpty &&
            credentialProvider.userToken != nil
    }
    
    func performSynchronization(completion: @escaping (Bool, Error?) -> Void) {
        let credentialProvider = UserAuthenticatedRequestCredentialProvider()
        
        let requestQueue = DispatchQueue(label: "com.connection_monitor.synchronization.requests", attributes: .concurrent)
        let stateQueue = DispatchQueue(label: "com.connection_monitor.synchronization.state", attributes: .concurrent)
        let group = DispatchGroup()
        var connectionsSet = Set<Connection.ConnectionStorage>()
        var error: Error? = nil
        
        // Get connections from the registry
        let connections = connectionsRegistry.getConnections()
        let startingCount = connections.count
        
        connections.forEach { connection in
            group.enter()
            requestQueue.async { [weak self] in
                let dataTask = self?.networkController.start(request: .fetchConnection(for: connection.id,
                                                                                       credentialProvider: credentialProvider))
                { (response) in
                    switch response.result {
                    case .success(let connection):
                        stateQueue.async {
                            self?.connectionsRegistry.update(with: connection, shouldNotify: false)
                            connectionsSet.insert(.init(connection: connection))
                            group.leave()
                        }
                    case .failure(let _error):
                        stateQueue.async {
                            error = _error
                            group.leave()
                        }
                    }
                }
                dataTask?.resume()
            }
        }

        requestQueue.async { [weak self] in
            group.wait()
            DispatchQueue.main.async {
                if let self = self {
                    self.subscribers.forEach { $0.processUpdate(with: self.connectionsRegistry.getConnections()) }
                }
                completion(connectionsSet.count == startingCount, error)
            }
        }
    }
}
