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

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        User.current.suggestedUserEmail = "jon+sdk@ifttt.com"
        
        Applet.Session.shared.inviteCode = "21790-7d53f29b1eaca0bdc5bd6ad24b8f4e1c"
        Applet.Session.shared.appletActivationRedirect = URL(string: "ifttt-api-example://sdk-callback")!
        Applet.Session.shared.userTokenProvider = IFTTTAuthenication()
        
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.backgroundColor = .white
        window.rootViewController = UINavigationController(rootViewController: HomeViewController())
        window.makeKeyAndVisible()
        self.window = window
        
        return true
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        if Applet.Session.shared.handleApplicationRedirect(url: url, options: options) {
            // This is an IFTTT SDK redirect, it will take over from here
            return true
        } else {
            // This is unrelated to the IFTTT SDK
            return false
        }
    }
}

struct IFTTTAuthenication: UserTokenProviding {
    func iftttUserToken(for session: Applet.Session) -> String? {
        let keychain = Keychain(service: "com.ifttt")
        return keychain["user_token"]
    }
}
