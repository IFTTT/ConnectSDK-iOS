# Location
The IFTTT Connect SDK supports native geofencing for connections using the IFTTT Location service. The geofence functionality is done using CoreLocation's region monitoring API. The documentation for this API is located [here](https://developer.apple.com/documentation/corelocation/monitoring_the_user_s_proximity_to_geographic_regions). 

<!-- TOC depthFrom:2 depthTo:6 withLinks:1 updateOnSave:1 orderedList:0 -->
- [Dependencies](#dependencies)
- [Prerequisites](#prerequisites)
- [Usage](#usage)

## Dependencies
- [CoreLocation geofence monitoring](https://developer.apple.com/documentation/corelocation/monitoring_the_user_s_proximity_to_geographic_regions)

## Prerequisites
- To use this library, you should have a connection on your service on IFTTT that connects the IFTTT Location service. To learn more about creating connections, please visit [developer documentation](https://platform.ifttt.com/docs/connections). 
- Add location background mode to your target's info.plist.<br> 
Example:
  ```
  <key>UIBackgroundModes</key>
  <array>
	<string>location</string>
  </array>
  ```e
  This is required in order for the operating system to launch the app when it's not in memory to respond to geofence updates. 
- Add the descriptions for the "Always Allow" and "When In Use" location permission level to your target's info.plist.<br>
Example:
  ```
  <key>NSLocationAlwaysAndWhenInUseUsageDescription</key><string>Grocery Express needs your location to be able to update your Connections and run your applets with your location.</string>
  <key>NSLocationWhenInUseUsageDescription</key><string>Grocery Express needs your location to be able to update your Connections and run your applets with your location.</string>
  ```

## Usage

### Initialization
To initialize synchronization and location monitoring, call `ConnectButtonController.initialize(options: InitializerOptions)`. This should be done as soon as possible and before the app is finished launching. This will not start the synchronization but it will start monitoring locations. If the app is launched in the background by a location update, calling this method will ensure that the location update will be captured by the SDK to be uploaded. If you would like the SDK to manage the [background process](#background-process) for you, set `enableSDKBackgroundProcess` on `InitializerOptions` to `true`. If you would like the SDK to show the native iOS permission prompts for you, set `showPermissionsPrompts` on `InitializerOptions` to `true`.

#### Background Process
The SDK supports the usage of background processes to periodically run synchronizations. This is done using the `BackgroundTasks` iOS framework. The documentation for this framework is located [here](https://developer.apple.com/documentation/backgroundtasks). When the app is configured to use `BackgroundTasks`, the app registers a task with identifier `com.ifttt.ifttt.synchronization_scheduler`. Furthermore, the app submits a `BGProcessingTaskRequest` with the identifier in the previous sentence. The `BGProcessingTaskRequest` is configured such that `requiresNetworkConnectivity` is set to `true`, `requiresExternalPower` is set to `true`, and `earliestBeginDate` is set to a value one hour in the future from the time that the app goes to the background. If the system launches the background process, the SDK runs a synchronization and then submits another task with the scheduler once the synchronization is complete. In this case, the `earliestBeginDate` of this background process is set to run one hour after the synchronization completes.

Alternatively, if you'd like to create your own background process/task but run a synchronization, you can call `ConnectButtonController.startBackgroundProcess(success:)`. The parameter to the method gets invoked once the synchronization is complete. To cancel a synchronization due to background process/task expiration, you can call `ConnectButtonController.stopCurrentSynchronization()`.

#### Opting in to the SDK schedule background processes
- Add the processing background mode to your target's info.plist. Example:
  ```
  <key>UIBackgroundModes</key>
  <array>
	<string>processing</string>
  </array>
  ```
- Add the IFTTT background process identifier: `com.ifttt.ifttt.synchronization_scheduler` to your target's info.plist for the key `BGTaskSchedulerPermittedIdentifiers`. Example: 
  ```
  <key>BGTaskSchedulerPermittedIdentifiers</key>
  <array>
	<string>com.ifttt.ifttt.synchronization_scheduler</string>
  </array>
  ```
- Call `ConnectButtonController.setupSDKBackgroundProcess()`. This method is required to be called before the app finishes launching. Not doing so will result in a `NSInternalInconsistencyException`.

### Setup
To setup synchronization, call `ConnectButtonController.setup(with:lifecycleSynchronizationOptions)`. This method allows for the passing of an `ConnectionCredentialProvider` to update the SDK with as well as an instance of `ApplicationLifecycleSynchronizationOptions` to determine what application lifecycle events the synchronization should be run on.

### Activation
To activate location monitoring and start synchronization, call `ConnectButtonController.activate(connections:)`. If the list of connection identifiers is known when activating the synchronization, pass this in to the method. This method can be called multiple times.

### Deactivation
To deactivate location monitoring and stop synchronization completely, call `ConnectButtonController.deactivate()`. Calling this will deactivate all registered geofences and remove all connections that are being monitored by the SDK. If you would like to restart location monitoring and synchronization after calling `ConnectButtonController.deactivate()`, call `ConnectButtonController.activate(connections:)`. This method can be called multiple times.

### Manual updates
To kick off a manual update of registered geofences and connection data, you can call `ConnectButtonController.update(with:)`.

### Logging
To enable verbose logging, set `ConnectButtonController.synchronizationLoggingEnabled = true`. To disable verbose logging, set `ConnectButtonController.synchronizationLoggingEnabled = false`. By default the logs get printed out using `NSLog`. If you'd like to supply your own logging handler, you may do so by setting a custom closure for `ConnectButtonController.synchnronizationLoggingHandler`. Setting this closure will not log any events using `NSLog`. If `ConnectButtonController.synchronizationLoggingEnabled = false` then neither the custom logging handler nor `NSLog` will be invoked to log events.

### Handling authentication failures
There exist cases in which the SDK can encounter an authentication failure. This could potentially happen due to a IFTTT user potentially getting deactivated or the token associated with the user being malformed. If you'd to get notifed of this failure and run any code, set a closure for the `ConnectButtonController.authenticationFailureHandler` property and it will get invoked after the SDK deactivates synchronization. It is the responsibility of the developer to perform SDK [setup](#Setup) and [activation](#Activation) after this occurs.

## Advanced
### Silent push notification support
While the SDK doesn't support receiving silent push notifications directly, if you've configured your app to receive silent push notifications and you'd like to run a  synchronization, you can call `ConnectButtonController.didReceiveSilentRemoteNotification(backgroundFetchCompletion:)` in the `didReceiveRemoteNotification(userInfo:fetchCompletionHandler)` `UIApplicationDelegate` method. The `backgroundFetchCompletion` closure will be invoked once the synchronization is complete with an appropriate `UIBackgroundFetchResult` enum value.

### Background Fetch support
The SDK doesn't directly invoke any background fetch methods. To use background fetch to run a synchronization while the app is in the background, you can call `ConnectButtonController.performFetchWithCompletionHandler(backgroundFetchCompletion:)` in the `performFetchWithCompletionHandler(completionHandler:)` `UIApplicationDelegate` method. The `backgroundFetchCompletion` closure will be invoked once the synchronization is complete with an appropriate `UIBackgroundFetchResult` enum value.

### Notes
- Automatic synchronization for a given connection will only be run if the connection has location triggers. Similarly, location region monitoring will only be started if the connection has location triggers setup.
- The SDK runs a synchronization by default for the following events:
    - When a connection is enabled via the user sliding the connect button
    - When a connection is disabled via the user sliding the connect button
    - When a connection is updated via displaying the connect button.
    - When the user enters a region specified by a connection geofence
    - When the user exits a region specified by a connection geofence
- Since the SDK needs to be able to store and read data while the app is in the background, the data is saved to the host app's container with the protection level `NSData.WritingOptions.completeFileProtectionUntilFirstUserAuthentication`.