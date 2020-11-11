//
//  ConnectionsMonitor.swift
//  IFTTT SDK
//
//  Copyright © 2020 IFTTT. All rights reserved.
//

import Foundation
import CoreLocation

struct UserAuthenticatedRequestCredentialProvider: ConnectionCredentialProvider {
    var inviteCode: String? { return Keychain.inviteCode }
    var userToken: String? { return Keychain.userToken }
    
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
    private let operationQueue: OperationQueue
    
    /// Creates an instance of `ConnectionsMonitor`
    ///
    /// - Parameters:
    ///     - connectionsRegistry: The registry of connections that should be monitored.
    /// - Returns: An initialized instance of `ConnectionsMonitor`.
    init(connectionsRegistry: ConnectionsRegistry) {
        self.connectionsRegistry = connectionsRegistry
        let operationQueue = OperationQueue()
        operationQueue.maxConcurrentOperationCount = 1
        self.operationQueue = operationQueue
    }
    
    // MARK: - SynchronizationSubscriber
    var name: String {
        return "ConnectionsMonitor"
    }
    
    func shouldParticipateInSynchronization(source: SynchronizationSource) -> Bool {
        let credentialProvider = UserAuthenticatedRequestCredentialProvider()
        return connectionsRegistry.getConnectionsCount() > 0 &&
            credentialProvider.userToken != nil &&
            source != .connectionRemoval &&
            source != .connectionsUpdate &&
            source != .connectionAddition &&
            operationQueue.operations.isEmpty
    }
    
    func performSynchronization(completion: @escaping (Bool, Error?) -> Void) {
        var error: Error? = nil
        // Get connections from the registry
        let connections = self.connectionsRegistry.getConnections()
        let startingCount = connections.count
        
        let completionOperation = BlockOperation {
            DispatchQueue.main.async {
                completion(self.connectionsRegistry.getConnectionsCount() == startingCount, error)
            }
        }
        
        let credentialProvider = UserAuthenticatedRequestCredentialProvider()

        connections.forEach { connection in
            let op = CancellableNetworkOperation(networkController: self.networkController,
                                                 request: .fetchConnection(for: connection.id,
                                                                           credentialProvider: credentialProvider))
            { [weak self] (response) in
                switch response.result {
                case .success(let connection):
                    self?.connectionsRegistry.update(with: connection, shouldNotify: false)
                case .failure(let _error):
                    if (_error as NSError).code != NSURLErrorCancelled {
                        error = _error
                    }
                }
            }
            completionOperation.addDependency(op)
            operationQueue.addOperation(op)
        }
        
        operationQueue.addOperation(completionOperation)
    }
    
    func start() { }
    
    func reset() {
        connectionsRegistry.removeAll()
        operationQueue.operations.reversed().forEach { $0.cancel() }
    }
}

/// Defines a cancellable `Operation` subclass to allow for cancellable network requests.
private class CancellableNetworkOperation: Operation {
    private var task: URLSessionDataTask? = nil
    private let completion: ConnectionNetworkController.CompletionHandler
    private weak var networkController: ConnectionNetworkController?
    private let request: Connection.Request

    init(networkController: ConnectionNetworkController,
         request: Connection.Request,
         _ completion: @escaping ConnectionNetworkController.CompletionHandler) {
        self.networkController = networkController
        self.request = request
        self.completion = completion
    }
    
    override func main() {
        task = networkController?.start(request: request, completion: { response in
            self.completion(response)
            self.completionBlock?()
        })
        task?.resume()
    }
    
    override func cancel() {
        super.cancel()
        task?.cancel()
    }
    
}
