# Location
The IFTTT Connect SDK supports native geo-fencing for connections using the IFTTT Location service. The geo-fence functionality is done using CoreLocation's region monitoring API. The documentation for this API is located [here](https://developer.apple.com/documentation/corelocation/monitoring_the_user_s_proximity_to_geographic_regions). 

<!-- TOC depthFrom:2 depthTo:6 withLinks:1 updateOnSave:1 orderedList:0 -->
- [Dependencies](#dependencies)
- [Setup](#setup)
- [Usage](#usage)

## Dependencies
- [CoreLocation geofence monitoring](https://developer.apple.com/documentation/corelocation/monitoring_the_user_s_proximity_to_geographic_regions)

## Usage
### Prerequisites
- To use this library, you should have a connection on your service on IFTTT that connects the IFTTT Location service. To learn more about creating connections, please visit [developer documentation](https://platform.ifttt.com/docs/connections). 
- Add location background mode to your target's info.plist.<br> 
Example:
  ```
  <key>UIBackgroundModes</key>
  <array>
	<string>location</string>
  </array>
  ```
  This is required in order for the operating system to launch the app when it's not in memory to response to geofence updates. 
- Add the descriptions for the "Always Allow" and "When In Use" location permission level to your target's info.plist.<br>
Example:
  ```
  <key>NSLocationAlwaysAndWhenInUseUsageDescription</key><string>Grocery Express needs your location to be able to update your Connections and run your applets with your location.</string>
  <key>NSLocationWhenInUseUsageDescription</key><string>Grocery Express needs your location to be able to update your Connections and run your applets with your location.</string>
  ```

## Initialization
- To initialize synchronization and location monitoring, call `ConnectButtonController.setup(with credentials: ConnectionCredentialProvider)`. This can be done after the app has made the determination that the current user is logged in. 

## Activation
To activate location monitoring and start synchronization, call `ConnectButtonController.activate(connections:)`. If the list of connection identifiers is known when activating the synchronization, pass this in to the method. This method can be called multiple times.

## Deactivation
To deactivate location monitoring and stop synchronization completely, call `ConnectButtonController.deactivate()`. If you would like to restart location monitoring and synchronization after calling ``ConnectButtonController.deactivate()`, call `ConnectButtonController.activate(connections:)`. This method can be called multiple times.

## Manual updates
To kick off a manual update of registered geofences and connection data, you can call `ConnectButtonController.update(with:)`.

## Logging
To enable verbose logging, set `ConnectButtonController.synchronizationLoggingEnabled = true`. To disable verbose logging, set `ConnectButtonController.synchronizationLoggingEnabled = false`. By default the logs get printed out using `NSLog`. If you'd like to supply your own logging handler, you may do so by setting a custom closure for `ConnectButtonController.synchnronizationLoggingHandler`. Setting this closure will not log any events using `NSLog`. If `ConnectButtonController.synchronizationLoggingEnabled = false` then neither the custom logging handler nor `NSLog` will be invoked to log events.

## Advanced
### Background Processes
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

### Silent push notification support
While the SDK doesn't support recieving silent push notifications directly, if you've configured your app to recieve silent push notifications and you'd like to run a  synchronization, you can call `ConnectButtonController.didReceiveSilentRemoteNotification(backgroundFetchCompletion:)` in the `didReceiveRemoteNotification(userInfo:fetchCompletionHandler)` `UIApplicationDelegate` method. The `backgroundFetchCompletion` closure will be invoked once the synchronization is complete with an appropriate `UIBackgroundFetchResult` enum value.

### Background Fetch support
The SDK doesn't directly invoke any background fetch methods but if want to use background fetch to run a synchronization while the app is in the background, you can call `ConnectButtonController.performFetchWithCompletionHandler(backgroundFetchCompletion:)` in the `performFetchWithCompletionHandler(completionHandler:)` `UIApplicationDelegate` method. The `backgroundFetchCompletion` closure will be invoked once the synchronization is complete with an appropriate `UIBackgroundFetchResult` enum value.

### Notes
- Automatic synchronization for a given connections will only be run if the connection has location triggers. Similarly, location region monitoring will only be started if the connection has location triggers setup.
- The SDK runs a synchronization by default for the following events:
    - When a connection is enabled via the user sliding the connect button
    - When a connection is disabled via the user sliding the connect button
    - When a connection is updated via displaying the connect button.
    - When the user enters a region specified by a connection geofence
    - When the user exits a region specified by a connection geofence
