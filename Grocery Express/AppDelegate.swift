//
//  AppDelegate.swift
//  SDK Example
//
//  Created by Jon Chmura on 8/31/18.
//  Copyright © 2018 IFTTT. All rights reserved.
//

import UIKit
import IFTTT_SDK

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    static let connectionRedirectURL = URL(string: "groceryexpress://connect_callback")!
    
    private let connectionRedirectHandler = AuthenticationRedirectHandler(authorizationRedirectURL: AppDelegate.connectionRedirectURL)
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        ConnectionCredentials(settings: Settings()).tokenRequest().start(nil)
        
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
