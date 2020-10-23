//
//  ConnectButtonController+Public.swift
//  IFTTT SDK
//
//  Copyright © 2020 IFTTT. All rights reserved.
//

import Foundation

extension ConnectButtonController {
    /// Determines whether or not logging for synchronization is enabled or not.
    public static var synchronizationLoggingEnabled: Bool = false
    
    /// If this closure is set, it will be called with the log statement instead of calling `print`. This handler will only be called if `synchronizationLoggingEnabled` is set to true
    public static var synchnronizationLoggingHandler: ((String) -> Void)?
    
    /// Determines whether or not logging for localization is enabled or not.
    public static var localizationLoggingEnabled: Bool = false
    
    /// If this closure is set, it will be called with the localization log statement instead of calling `print`. This handler will only be called if `localizationLoggingEnabled` is set to true
    public static var localizationLoggingHandler: ((String) -> Void)?
    
    /// This method should be called prior to calling any other static method on `ConnectButtonController`. It performs setup of the location component of the SDK.
    ///
    /// - Parameters:
    ///     - credentials: An object conforming to `ConnectionCredentialProvider` which is used to setup the SDK.
    ///     - lifecycleSynchronizationOptions: An instance of `ApplicationLifecycleSynchronizationOptions` that defines which app lifecycle events the synchronization should occur on. If this parameter is not set, a default value of `ApplicationLifecycleSynchronizationOptions.all` will be used.
    public static func setup(with credentials: ConnectionCredentialProvider,
                             lifecycleSynchronizationOptions: ApplicationLifecycleSynchronizationOptions = .all) {
        Keychain.userToken = credentials.userToken
        Keychain.inviteCode = credentials.inviteCode
        ConnectionsSynchronizer.setup(lifecycleSynchronizationOptions: lifecycleSynchronizationOptions)
    }
    
    /// Call this method to activate the synchronization. This starts synchronization for the parameter connections.
    ///
    /// - Parameters:
    ///     - connections: An optional list of `Connection` to activate synchronization with.
    public static func activate(connections ids: [String]? = nil) {
        ConnectionsSynchronizer.shared().activate(connections: ids)
    }
    
    /// Call this method to deactivate the synchronization of connection and native service data. This stops synchronization and performs cleanup of any stored data.
    public static func deactivate() {
        ConnectionsSynchronizer.shared().deactivate()
    }
    
    /// Call this method to run a manual synchronization.
    ///
    /// - Parameters:
    ///     - iftttUserToken: This optional IFTTT user token will be stored by the SDK to use in synchronization. If this parameter is nil, the parameter will be ignored.
    public static func update(with credentials: ConnectionCredentialProvider? = nil) {
        if let credentials = credentials {
            Keychain.userToken = credentials.userToken
            Keychain.inviteCode = credentials.inviteCode
        }
        ConnectionsSynchronizer.shared().update()
    }
    
    /// Hook to be called when the `UIApplicationDelegate` recieves the `application:performFetchWithCompletionHandler:` method call. This method should only be called when your app recieves a background fetch request from the system.
    ///
    /// - Parameters:
    ///     - backgroundFetchCompletion: The block that's executed when the synchronization is complete. When this closure is called, the fetch result value that best describes the results of the synchronization is provided.
    public static func performFetchWithCompletionHandler(backgroundFetchCompletion: ((UIBackgroundFetchResult) -> Void)?) {
        ConnectionsSynchronizer.shared().performFetchWithCompletionHandler(backgroundFetchCompletion: backgroundFetchCompletion)
    }
    
    /// Hook to be called when the `UIApplicationDelegate` recieves the `application:didReceiveRemoteNotification:` method call. This method should only be called when your app recieves a silent push notification.
    /// 
    /// - Parameters:
    ///     - backgroundFetchCompletion: The block that's executed when the synchronization is complete. When this closure is called, the fetch result value that best describes the results of the synchronization is provided.
    public static func didReceiveSilentRemoteNotification(backgroundFetchCompletion: ((UIBackgroundFetchResult) -> Void)?) {
        ConnectionsSynchronizer.shared().didReceiveSilentRemoteNotification(backgroundFetchCompletion: backgroundFetchCompletion)
    }
    
    /// Hook to be called if you'd like the SDK to setup a background process to run synchronizations while the app is in the background. This method is required to be called before the app finishes launching. Not doing so will result in a `NSInternalInconsistencyException`.
    public static func setupSDKBackgroundProcess() {
        ConnectionsSynchronizer.shared().setupBackgroundProcess()
    }
    
    /// Hook to be called if you'd like to start a synchronization with a background process. It is the responsibility of the caller to manage the appropriate background process with the system and to handle the expiration of the task. For your convenience, `stopCurrentSynchronization` should called in the expiration handler of the background process.
    ///
    /// - Parameters:
    ///     - success: A closure with a boolean argument that will return true/false as to whether or not the synchronization failed or succeeded.
    public static func startBackgroundProcess(success: @escaping BoolClosure) {
        ConnectionsSynchronizer.shared().startBackgroundProcess(success: success)
    }
    
    /// Hook to be called if you'd like to stop the current synchronization task. This will cancel all internal in-flight network requests that the SDK makes as a part of its synchronization process.
    public static func stopCurrentSynchronization() {
        ConnectionsSynchronizer.shared().stopCurrentSynchronization()
    }
}
