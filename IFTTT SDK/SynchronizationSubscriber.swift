//
//  SynchronizationSubscriber.swift
//  IFTTT SDK
//
//  Copyright © 2020 IFTTT. All rights reserved.
//

import Foundation

/// Defines sources that kick off a synchronization
enum SynchronizationSource: CustomStringConvertible {
    /// Defines a region entered or region update.
    case regionsUpdate
    
    /// Used when a user's connections gets updated.
    case connectionsUpdate
    
    /// Used when a user's connection gets removed
    case connectionRemoval
    
    /// Used when a user's connection is added to the registry
    case connectionAddition
    
    /// Used when the application did become active
    case appDidBecomeActive
    
    /// Used when the application goes to the background
    case appBackgrounded
    
    /// Used when the SDK needs to run a synchronization due to a force update 
    case forceUpdate
    
    /// Used when the SDK needs to run a synchronization due to activation
    case connectionActivation
    
    /// Used when the system initiates a background fetch. Not used.
    case backgroundFetch
    
    /// Used when the SDK has a background process run which is scheduled by the SDK.
    case internalBackgroundProcess
    
    /// Used when the SDK has a background process run which is scheduled by the user of the SDK.
    case externalBackgroundProcess
    
    /// Used when the app gets a silen push notification. Not used.
    case silentPushNotification
    
    /// Determines whether or not the source is a background process or not.
    /// - Returns: A bool as to whether or not the source is a background process or not.
    func isBackgroundProcess() -> Bool {
        return self == .internalBackgroundProcess || self == .externalBackgroundProcess
    }
    
    var description: String {
        switch self {
        case .appBackgrounded:
            return "Application entered background"
        case .appDidBecomeActive:
            return "Application did become active"
        case .backgroundFetch:
            return "Background fetch"
        case .connectionAddition:
            return "Connection added"
        case .connectionRemoval:
            return "Connection removed"
        case .connectionsUpdate:
            return "Connections were updated"
        case .externalBackgroundProcess:
            return "Host app started background process"
        case .forceUpdate:
            return "Host app triggered a force update"
        case .connectionActivation:
            return "Connections were activated"
        case .internalBackgroundProcess:
            return "SDK started background process"
        case .regionsUpdate:
            return "User triggered geofence update"
        case .silentPushNotification:
            return "Host app received a silent push notification"
        }
    }
}

/// Conform to this protocol and register with the `SynchronizationManager` be notified when a synchronization is starting.
protocol SynchronizationSubscriber {
    
    /// A name used to identifier this synchronization subscriber. Should be a constant.
    var name: String { get }
    
    /// Asks the `SynchronizationSubscriber` if it wishes to be part on an upcoming synchronization.
    ///
    /// - Parameters:
    ///   - source: The source of the synchronization
    /// - Returns: True to be included in the synchronization
    func shouldParticipateInSynchronization(source: SynchronizationSource) -> Bool
    
    /// This instructs a `SynchronizationSubscriber` to begin a synchronization
    ///
    /// - Parameters:
    ///   - completion: Call this when synchronization is complete
    func performSynchronization(completion: @escaping (_ newData: Bool, _ syncError: Error?) -> Void)
    
    /// Hook that is called to reset the subscriber. Called when global synchronization is stopped. Use this hook to tear down any notification observers, clear out cached data, etc.
    func reset()
    
    /// Hook that is called to start the subscriber.
    func start()
}
