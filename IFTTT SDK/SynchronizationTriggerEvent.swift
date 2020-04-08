//
//  SynchronizationSubscriber.swift
//  IFTTT SDK
//
//  Copyright © 2020 IFTTT. All rights reserved.
//

import Foundation

typealias BackgroundFetchClosure = (UIBackgroundFetchResult) -> Void

/// Defines an event which should trigger a background synchronization
struct SynchronizationTriggerEvent {
    
    /// The source of the synchronization trigger event
    let source: SynchronizationSource
    
    /// The associated background fetch completion handler. This relates to background handler for push notifications.
    let backgroundFetchCompletionHandler: BackgroundFetchClosure?
}
