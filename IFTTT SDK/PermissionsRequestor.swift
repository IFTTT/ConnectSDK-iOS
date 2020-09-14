//
//  PermissionsRequestor.swift
//  IFTTT SDK
//
//  Copyright © 2020 IFTTT. All rights reserved.
//

import Foundation
import CoreLocation

/// Handles requesting device permissions
final class PermissionsRequestor: SynchronizationSubscriber {
    private let locationManager = CLLocationManager()
    
    private let queue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        return queue
    }()
    
    private let registry: ConnectionsRegistry
    
    init(registry: ConnectionsRegistry) {
        self.registry = registry
    }

    private func processUpdate(with connections: Set<Connection.ConnectionStorage>) {
        let operations = connections.reduce(.init()) { (currSet, connections) -> Set<Trigger> in
            return currSet.union(connections.activeTriggers)
        }
        .compactMap { permission -> Library in
            switch permission {
            case .location:
                return LocationLibrary(locationManager: locationManager)
            }
        }.map { BlockOperation(library: $0) }
        
        queue.addOperations(operations, waitUntilFinished: false)
    }
    
    var name: String = "PermissionsRequestor"
    
    func shouldParticipateInSynchronization(source: SynchronizationSource) -> Bool {
        return !registry.getConnections().isEmpty
            && UserAuthenticatedRequestCredentialProvider.standard.userToken != nil
            && UIApplication.shared.applicationState == .active
    }
    
    func performSynchronization(completion: @escaping (Bool, Error?) -> Void) {
        processUpdate(with: registry.getConnections())
        completion(true, nil)
    }
    
}

private extension BlockOperation {
    convenience init(library: Library) {
        self.init {
            let semaphore = DispatchSemaphore(value: 0)
            DispatchQueue.main.async {
                library.requestAccess { _ in
                    semaphore.signal()
                }
            }
            semaphore.wait()
        }
    }
}
