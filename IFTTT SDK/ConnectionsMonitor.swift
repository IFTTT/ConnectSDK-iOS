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
                if response.isAuthenticationFailure {
                    error = NetworkControllerError.authenticationFailure
                    return
                }
                
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
        let connectionsStoppedMonitoring = connectionsRegistry.getConnections()
            .map { $0.id }
            .joined(separator: ", ")
            .description
        ConnectButtonController.synchronizationLog("Deactivating synchronizations for connections: \(connectionsStoppedMonitoring)")
        connectionsRegistry.removeAll()
        operationQueue.operations.reversed().forEach { $0.cancel() }
    }
}

/// Defines a cancellable `Operation` subclass to allow for cancellable network requests.
private class CancellableNetworkOperation: Operation {
    /// The current in-flight network request
    private var task: URLSessionDataTask? = nil
    
    /// The completion closure to invoke once the request is completed
    private let completion: ConnectionNetworkController.ConnectionResponseClosure
    
    /// The network controller to perform requests with
    private weak var networkController: ConnectionNetworkController?
    
    /// The request to perform
    private let request: Connection.Request

    /// Creates an instance of `CancellableNetworkOperation`.
    init(networkController: ConnectionNetworkController,
         request: Connection.Request,
         _ completion: @escaping ConnectionNetworkController.ConnectionResponseClosure) {
        self.networkController = networkController
        self.request = request
        self.completion = completion
    }
    
    /// State for this operation.
    @objc private enum OperationState: Int {
        case ready
        case executing
        case finished
    }
    
    /// Concurrent queue for synchronizing access to `state`.
    private let stateQueue = DispatchQueue(label: "com.ifttt.connections_monitor.rw.state", attributes: .concurrent)
    
    /// Private backing stored property for `state`.
    private var _state: OperationState = .ready
    
    /// The state of the operation
    @objc private dynamic var state: OperationState {
        get {
            return stateQueue.sync { _state }
        }
        set {
            stateQueue.async(flags: .barrier) { self._state = newValue }
        }
    }
    
    override var isReady: Bool {
        return state == .ready && super.isReady
    }
    
    override var isExecuting: Bool {
        return state == .executing
    }
    
    override var isFinished: Bool {
        return state == .finished
    }
    
    override var isAsynchronous: Bool {
        return true
    }

    open override class func keyPathsForValuesAffectingValue(forKey key: String) -> Set<String> {
        let keys = ["isReady", "isFinished", "isExecuting"]
        if keys.contains(key) {
            return .init(arrayLiteral: #keyPath(state))
        }
        
        return super.keyPathsForValuesAffectingValue(forKey: key)
    }
    
    override func start() {
        if isCancelled {
            state = .finished
            return
        }
        
        state = .executing
        
        main()
    }
    
    override func main() {
        task = networkController?.start(request: request, completion: { [weak self] response in
            guard let self = self else { return }
            self.completion(response)
            self.finish()
        })
        task?.resume()
    }
    
    override func cancel() {
        task?.cancel()
        finish()
    }
    
    /// Call this method to finish the operation
    private func finish() {
        if !isFinished {
            state = .finished
        }
    }
}
