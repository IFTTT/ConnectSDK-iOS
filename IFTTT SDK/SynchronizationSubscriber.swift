//
//  SynchronizationSubscriber.swift
//  IFTTT SDK
//
//  Copyright © 2020 IFTTT. All rights reserved.
//

import Foundation

/// Defines sources that kick off a synchronization
enum SynchronizationSource {
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
    
    /// Used when the system initiates a background fetch. Not used.
    case backgroundFetch
    
    /// Used when the system initiates a background process run
    case backgroundProcess
    
    /// Used when the app gets a silen push notification. Not used.
    case silentPushNotification
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
}
