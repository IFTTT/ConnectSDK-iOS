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
    
    static var standard = UserAuthenticatedRequestCredentialProvider()
}

/// Monitors connections to update native services.
class ConnectionsMonitor: SynchronizationSubscriber {
    
    /// The registry of connections the user has currently enabled.
    private let connectionsRegistry: ConnectionsRegistry 
    
    /// Network controller to use in making requests
    private let networkController = ConnectionNetworkController()
    
    /// The operation queue to handle synchronization of multiple network requests
    private let operationQueue = OperationQueue()
    
    /// Creates an instance of `ConnectionsMonitor`
    ///
    /// - Parameters:
    ///     - connectionsRegistry: The registry of connections that should be monitored.
    /// - Returns: An initialized instance of `ConnectionsMonitor`.
    init(connectionsRegistry: ConnectionsRegistry) {
        self.connectionsRegistry = connectionsRegistry
    }
    
    // MARK: - SynchronizationSubscriber
    var name: String {
        return "ConnectionsMonitor"
    }
    
    func shouldParticipateInSynchronization(source: SynchronizationSource) -> Bool {
        let credentialProvider = UserAuthenticatedRequestCredentialProvider()
        return !connectionsRegistry.getConnections().isEmpty &&
            credentialProvider.userToken != nil &&
            source != .connectionRemoval &&
            source != .connectionsUpdate
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

        requestQueue.async {
            group.wait()
            DispatchQueue.main.async {
                completion(connectionsSet.count == startingCount, error)
            }
        }
    }
}
