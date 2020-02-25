//
//  AppDelegate.swift
//  SDK Example
//
//  Copyright © 2019 IFTTT. All rights reserved.
//

import UIKit
import IFTTTConnectSDK

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    static let connectionRedirectURL = URL(string: "groceryexpress://connect_callback")!
    
    private let connectionRedirectHandler = ConnectionRedirectHandler(redirectURL: AppDelegate.connectionRedirectURL)
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        TokenRequest(credentials: ConnectionCredentials(settings: Settings())).start()
        ConnectButtonController.analyticsEnabled = true
        return true
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
}
