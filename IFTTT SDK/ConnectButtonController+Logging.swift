//
//  ConnectButtonController+Logging.swift
//  IFTTT SDK
//
//  Copyright © 2020 IFTTT. All rights reserved.
//

import Foundation

extension ConnectButtonController {
    static func log(handler: ((String) -> Void)?,
                    isEnabled: Bool,
                    event: String,
                    domain: String) {
        guard isEnabled else { return }
        if let handler = handler {
            handler(event)
        } else {
            NSLog("[ConnectSDK/\(domain)] \(event)")
        }
    }
    
    /// Logs localization events to the console only if `localizationLoggingEnabled` is `true`.
    ///
    /// - Parameters:
    ///     - event: A string corresponding to the event to log.
    static func localizationLog(_ event: String) {
        log(handler: localizationLoggingHandler,
            isEnabled: localizationLoggingEnabled,
            event: event,
            domain: "Localization")
    }
    
    /// Logs synchronization events to the console only if `synchronizationLoggingEnabled` is `true`.
    ///
    /// - Parameters:
    ///     - event: A string corresponding to the event to log.
    static func synchronizationLog(_ event: String) {
        log(handler: synchnronizationLoggingHandler,
            isEnabled: synchronizationLoggingEnabled,
            event: event,
            domain: "Synchronization")
    }
}
