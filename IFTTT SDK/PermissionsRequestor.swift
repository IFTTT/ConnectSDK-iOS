//
//  PermissionsRequestor.swift
//  IFTTT SDK
//
//  Copyright © 2020 IFTTT. All rights reserved.
//

import Foundation
import CoreLocation

/// Handles requesting device permissions
final class PermissionsRequestor {
    var showPermissionsPrompts = true
    
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

    func processUpdate(with connections: Set<Connection.ConnectionStorage>) {
        if !canUpdate() { return }
        
        let operations = connections.reduce(.init()) { (currSet, connections) -> Set<Trigger> in
            return currSet.union(connections.allTriggers)
        }
        .compactMap { permission -> Library in
            switch permission {
            case .location:
                return LocationLibrary(locationManager: locationManager)
            }
        }.map { BlockOperation(library: $0) }
        
        queue.addOperations(operations, waitUntilFinished: false)
    }
    
    private func canUpdate() -> Bool {
        return !registry.getConnections().isEmpty
            && UserAuthenticatedRequestCredentialProvider.standard.userToken != nil
            && UIApplication.shared.applicationState == .active
            && showPermissionsPrompts
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
