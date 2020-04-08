//
//  AppDelegate.swift
//  SDK Example
//
//  Copyright © 2019 IFTTT. All rights reserved.
//

import UIKit
import IFTTTConnectSDK
import CoreLocation

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    let locationManager = CLLocationManager()
    
    static let connectionRedirectURL = URL(string: "groceryexpress://connect_callback")!
    
    private let connectionRedirectHandler = ConnectionRedirectHandler(redirectURL: AppDelegate.connectionRedirectURL)
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        TokenRequest(credentials: ConnectionCredentials(settings: Settings())).start()
        ConnectButtonController.analyticsEnabled = true
        ConnectionsSynchronizer.shared.applicationDidFinishLaunching()
        return true
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        ConnectionsSynchronizer.shared.applicationDidEnterBackground()
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        if connectionRedirectHandler.handleApplicationRedirect(url: url, options: options) {
            // This is an IFTTT SDK redirect, it will take over from here
            return true
        } else {
            // This is unrelated to the IFTTT SDK
            return false
        }
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        if let aps = userInfo["aps"] as? [String: Any],
            let isSilentPushNotification = aps["content-available"] as? Bool,
            isSilentPushNotification {
            ConnectionsSynchronizer.shared.didReceiveSilentRemoteNotification(backgroundFetchCompletion: completionHandler)
        }
    }
    
    func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        ConnectionsSynchronizer.shared.didReceiveSilentRemoteNotification(backgroundFetchCompletion: completionHandler)
    }
}
