//
//  ConnectButtonController+Public.swift
//  IFTTT SDK
//
//  Copyright © 2020 IFTTT. All rights reserved.
//

import Foundation

extension ConnectButtonController {
    public static func login() {
        Keychain.resetIfNecessary(force: false)
        ConnectionsSynchronizer.shared.start()
    }
    
    public static func logout() {
        Keychain.reset()
        ConnectionsSynchronizer.shared.stop()
    }
    
    public static func update(with iftttUserToken: String? = nil) {
        if let iftttUserToken = iftttUserToken {
            Keychain.userToken = iftttUserToken
        }
        ConnectionsSynchronizer.shared.update()
    }
    
    /// Hook to be called when the `UIApplicationDelegate` recieves the `application:performFetchWithCompletionHandler:` method call. This method should only be called when your app recieves a background fetch request from the system.
    public static func performFetchWithCompletionHandler(backgroundFetchCompletion: ((UIBackgroundFetchResult) -> Void)?) {
        ConnectionsSynchronizer.shared.performFetchWithCompletionHandler(backgroundFetchCompletion: backgroundFetchCompletion)
    }
    
    /// Hook to be called when the `UIApplicationDelegate` recieves the `application:didReceiveRemoteNotification:` method call. This method should only be called when your app recieves a silent push notification.
    public static func didReceiveSilentRemoteNotification(backgroundFetchCompletion: ((UIBackgroundFetchResult) -> Void)?) {
        ConnectionsSynchronizer.shared.didReceiveSilentRemoteNotification(backgroundFetchCompletion: backgroundFetchCompletion)
    }
    
    /// Hook to be called if you'd like to start a synchronization with a background process. It is the responsibility of the caller to manage the appropriate background process with the system and to handle the expiration of the task. For your convenience, `stopCurrentSynchronization` should called in the expiration handler of the background process.
    ///
    /// - Parameters:
    ///     - success: A closure with a boolean argument that will return true/false as to whether or not the synchronization failed or succeeded.
    public static func startBackgroundProcess(success: @escaping BoolClosure) {
        ConnectionsSynchronizer.shared.startBackgroundProcess(success: success)
    }
    
    /// Hook to be called if you'd like to stop the current synchronization task. This will cancel all internal in-flight network requests that the SDK makes as a part of its synchronization process.
    public static func stopCurrentSynchronization() {
        ConnectionsSynchronizer.shared.stopCurrentSynchronization()
    }
}
