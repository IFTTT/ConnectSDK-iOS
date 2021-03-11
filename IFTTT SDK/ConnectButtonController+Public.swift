//
//  ConnectButtonController+Public.swift
//  IFTTT SDK
//
//  Copyright © 2020 IFTTT. All rights reserved.
//

import Foundation

/// Describes options to initialize the SDK with
public struct InitializerOptions {
    
    /// Enables the SDK to handle registering and running a background process to periodically run synchronizations.
    public let enableSDKBackgroundProcess: Bool
    
    /// Flag that determines whether or not permissions prompts should be shown in the flow.
    public let showPermissionsPrompts: Bool
    
    /// The standard initializer options.
    ///
    /// This does the following:
    /// - Sets `enableSDKBackgroundProcess` to false.
    public static var standard = InitializerOptions()
    
    /// Creates an instance of `InitializerOptions`.
    ///
    /// - Parameters:
    ///     - enableSDKBackgroundProcess: A `Bool` that allows the SDK to enable background processes. Defaults to `false`. If you'd like the SDK to manage a background process for you, set this to `true`.
    ///     - showPermissionsPrompts: A `Bool` that determines whether or not the SDK should show permissions prompts. Defaults to `false`. If you'd like the SDK to show permissions prompts for you, set this to `true`.
    public init(enableSDKBackgroundProcess: Bool = false, showPermissionsPrompts: Bool = false) {
        self.enableSDKBackgroundProcess = enableSDKBackgroundProcess
        self.showPermissionsPrompts = showPermissionsPrompts
    }
}

extension ConnectButtonController {
    /// Determines whether or not logging for synchronization is enabled or not.
    public static var synchronizationLoggingEnabled: Bool = false
    
    /// If this closure is set, it will be called with the log statement instead of calling `print`. This handler will only be called if `synchronizationLoggingEnabled` is set to true
    public static var synchnronizationLoggingHandler: ((String) -> Void)?
    
    /// Determines whether or not logging for localization is enabled or not.
    public static var localizationLoggingEnabled: Bool = false
    
    /// If this closure is set, it will be called with the localization log statement instead of calling `print`. This handler will only be called if `localizationLoggingEnabled` is set to true
    public static var localizationLoggingHandler: ((String) -> Void)?
    
    /// If this closure is set, it will be called after the synchronization is interrupted due to an authentication failure. This closure will be invoked after synchronization is deactivated.
    public static var authenticationFailureHandler: (() -> Void)?
    
    /// Initializes the SDK with options. This method should be called prior to calling any other static method on `ConnectButtonController`. It performs setup of the location component of the SDK. Call this method in `UIApplicationDelegate`'s `didFinishLaunchingWithOptions` or `willFinishLaunchingWithOptions`.
    ///
    /// This method will do the following:
    /// - Initialize the mechanism for synchronization but it will not start it.
    /// - Start the location service to receive any location updates that might have occurred
    /// - (If necessary) Setup SDK provided background process with the system. This allows the app to run synchronizations while the app is in memory and in the background. In this case, this method must be called before the app finishes launching. Failure to do so will result in a `NSInternalInconsistencyException`.
    ///
    /// - Parameters:
    ///     - options: An instance of `InitializerOptions` to initialize the SDK with.
    public static func initialize(options: InitializerOptions = .standard) {
        let sharedSynchronizer = ConnectionsSynchronizer.shared
        
        sharedSynchronizer.setShowPermissionsPrompts(options.showPermissionsPrompts)
        
        if options.enableSDKBackgroundProcess {
            sharedSynchronizer.setupBackgroundProcess()
        } else {
            sharedSynchronizer.teardownBackgroundProcess()
        }
    }
    
    /// Performs setup of the SDK. Starts the synchronization of in the SDK. Registers background process with the system if desired.
    ///
    /// - Parameters:
    ///     - credentials: An optional object conforming to `ConnectionCredentialProvider` which is used to setup the SDK. If this is nil, the SDK will attempt to use cached values.
    ///     - lifecycleSynchronizationOptions: An instance of `ApplicationLifecycleSynchronizationOptions` that defines which app lifecycle events the synchronization should occur on. If this parameter is not set, a default value of `ApplicationLifecycleSynchronizationOptions.all` will be used.
    public static func setup(with credentials: ConnectionCredentialProvider?,
                             lifecycleSynchronizationOptions: ApplicationLifecycleSynchronizationOptions = .all) {
        if let credentials = credentials {
            Keychain.update(with: credentials)
        }
        ConnectionsSynchronizer.shared.setup(lifecycleSynchronizationOptions: lifecycleSynchronizationOptions)
    }
    
    /// Call this method to activate the synchronization. This starts synchronization for the parameter connections.
    ///
    /// - Parameters:
    ///     - connections: An optional list of `Connection` to activate synchronization with.
    public static func activate(connections ids: [String]? = nil) {
        ConnectionsSynchronizer.shared.activate(connections: ids)
    }
    
    /// Call this method to deactivate the synchronization of connection and native service data. This stops synchronization and performs cleanup of any stored data. This will also remove any registered geofences.
    public static func deactivate() {
        ConnectionsSynchronizer.shared.deactivate()
    }
    
    /// Call this method to run a manual synchronization.
    ///
    /// - Parameters:
    ///     - iftttUserToken: This optional IFTTT user token will be stored by the SDK to use in synchronization. If this parameter is nil, the parameter will be ignored.
    public static func update(with credentials: ConnectionCredentialProvider? = nil) {
        if let credentials = credentials {
            Keychain.update(with: credentials)
        }
        ConnectionsSynchronizer.shared.update()
    }
    
    /// Hook to be called when the `UIApplicationDelegate` recieves the `application:performFetchWithCompletionHandler:` method call. This method should only be called when your app recieves a background fetch request from the system.
    ///
    /// - Parameters:
    ///     - backgroundFetchCompletion: The block that's executed when the synchronization is complete. When this closure is called, the fetch result value that best describes the results of the synchronization is provided.
    public static func performFetchWithCompletionHandler(backgroundFetchCompletion: ((UIBackgroundFetchResult) -> Void)?) {
        ConnectionsSynchronizer.shared.performFetchWithCompletionHandler(backgroundFetchCompletion: backgroundFetchCompletion)
    }
    
    /// Hook to be called when the `UIApplicationDelegate` recieves the `application:didReceiveRemoteNotification:` method call. This method should only be called when your app recieves a silent push notification.
    /// 
    /// - Parameters:
    ///     - backgroundFetchCompletion: The block that's executed when the synchronization is complete. When this closure is called, the fetch result value that best describes the results of the synchronization is provided.
    public static func didReceiveSilentRemoteNotification(backgroundFetchCompletion: ((UIBackgroundFetchResult) -> Void)?) {
        ConnectionsSynchronizer.shared.didReceiveSilentRemoteNotification(backgroundFetchCompletion: backgroundFetchCompletion)
    }
    
    /// Hook to be called if you'd like to start a synchronization with a background process. It is the responsibility of the caller to manage the appropriate background process with the system and to handle the expiration of the task. For your convenience, `stopCurrentSynchronization` is provided to be called in the expiration handler of the background process.
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
    
    /// Call this method to toggle geofences on and off for the parameter connection id.
    ///
    /// - Parameters:
    ///     - enabled: A boolean as to whether or not the geofences should be enabled or disabled.
    ///     - connectionId: The id of the connection that the geofences should be enabled or disabled for.
    public static func setGeofencesEnabled(enabled: Bool, for connectionId: String) {
        ConnectionsSynchronizer.shared.setGeofencesEnabled(enabled, for: connectionId)
    }
    
    /// Returns the enabled state for geofences for the parameter connection.
    ///
    /// - Parameters:
    ///     - connectionId: The connection id to get the enabled status for.
    /// - Returns: The enabled state for geofences for the given connection.
    public static func geofencesEnabled(for connectionId: String) -> Bool {
        return ConnectionsSynchronizer.shared.geofencesEnabled(for: connectionId)
    }
    
    /// Allows for a closure to be executed when the OS starts a background process set up by the SDK.
    ///
    /// The `launchHandler` parameter will get run on a background thread. `expirationHandler` gets called by the system right before the amount of allotted time for the background process is zero. Use the `expirationHandler` to perform any cleanup of resources used or allocated in `launchHandler`. `expirationHandler` will be executed on the same background thread as `launchHandler`.
    ///
    /// - Parameters:
    ///     - launchHandler: A closure to execute when the OS starts a background process set up by the SDK.
    ///     - expirationHandler: A closure to execute when the allotted time for the background process is zero.
    public static func setBackgroundProcessClosures(launchHandler: VoidClosure?, expirationHandler: VoidClosure?) {
        ConnectionsSynchronizer.shared.setDeveloperBackgroundProcessClosures(launchHandler: launchHandler,
                                                                               expirationHandler: expirationHandler)
    }
}
