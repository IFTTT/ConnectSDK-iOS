//
//  SynchronizationSubscriber.swift
//  IFTTT SDK
//
//  Copyright © 2020 IFTTT. All rights reserved.
//

import UIKit

/// Describes a closure that's invoked after a sync subscriber finishes its task
///
/// - Parameters:
///     - backgroundFetchResult: An instance of `UIBackgroundFetchResult` which describes ahat the result of the fetch result is.
///     - authenticationFailure: A bool which determines whether or not the sync operation resulted in an authentication failure.
typealias BackgroundFetchClosure = (UIBackgroundFetchResult, Bool) -> Void

/// Defines an event which should trigger a background synchronization
struct SynchronizationTriggerEvent {
    
    /// The source of the synchronization trigger event
    let source: SynchronizationSource
    
    /// The associated background fetch completion handler. This relates to background handler for push notifications.
    let completionHandler: BackgroundFetchClosure?
}
