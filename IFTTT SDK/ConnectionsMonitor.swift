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
    /// A hook for a native service to be able to update itself based on the user's connections.
    ///
    /// - Parameters:
    ///     - connections: The updated set of `Connection`.
    func processUpdate(with connections: Set<Connection>)
}

/// Monitors connections to update native services.
class ConnectionsMonitor: SynchronizationSubscriber {
    
    private struct ConnectionFetchCredentialProvider: ConnectionCredentialProvider {
        var inviteCode: String? { return Keychain.getValue(for: Keychain.Key.InviteCode) }
        var userToken: String? { return Keychain.getValue(for: Keychain.Key.UserToken) }
        
        /// This isn't used in the network request.
        var oauthCode: String = ""
    }
    
    /// A list of subscribers to update when a connection gets updated
    private let subscribers: [ConnectionMonitorSubscriber]
    
    /// Network controller to use in making requests
    private let networkController = ConnectionNetworkController()
    
    /// The operation queue to handle synchronization of multiple network requests
    private let operationQueue = OperationQueue()
    
    /// Creates an instance of `ConnectionsMonitor`
    ///
    /// - Parameters:
    ///     - location: An instance of `LocationService` to use when we the Set of connections get updated.
    /// - Returns: An initialized instance of `ConnectionsMonitor`.
    init(location: LocationService) {
        self.subscribers = [location]
    }
    
    /// Updates subscribers with this connection.
    ///
    /// - Parameters:
    ///     - connection: The connection to run updates for
    func update(with connections: Set<Connection>) {
        subscribers.forEach { $0.processUpdate(with: connections) }
    }
    
    // MARK: - SynchronizationSubscriber
    var name: String {
        return "ConnectionsMonitor"
    }
    
    func shouldParticipateInSynchronization(source: SynchronizationSource) -> Bool {
        return true
    }
    
    func performSynchronization(completion: @escaping (Bool, Error?) -> Void) {
        let requestQueue = DispatchQueue(label: "com.connection_monitor.synchronization.requests", attributes: .concurrent)
        let stateQueue = DispatchQueue(label: "com.connection_monitor.synchronization.state", attributes: .concurrent)
        let group = DispatchGroup()
        var connectionsSet = Set<Connection>()
        var error: Error? = nil
        
        // Get connection ids from the registry
        let connectionIds = ConnectionsRegistry.shared.getConnections()

        connectionIds.forEach { connectionId in
            group.enter()
            requestQueue.async { [weak self] in
                let credentialProvider = ConnectionFetchCredentialProvider()
                let dataTask = self?.networkController.start(request: .fetchConnection(for: connectionId, credentialProvider: credentialProvider)) { (response) in
                    switch response.result {
                    case .success(let connection):
                        ConnectionsRegistry.shared.update(with: connection, shouldNotify: false)
                        stateQueue.async {
                            connectionsSet.insert(connection)
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
                self?.subscribers.forEach { $0.processUpdate(with: connectionsSet) }
                completion(!connectionIds.isEmpty, error)
            }
        }
    }
}
