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

    static var shared: AppDelegate?
    
    var window: UIWindow?
    
    func login() {
        window?.rootViewController = UINavigationController(rootViewController: HomeViewController())
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        AppDelegate.shared = self
        
        IFTTTAuthenication.shared.setIftttUserToken(nil)
        
        User.current.suggestedUserEmail = "jon@ifttt.com"
        
        Applet.Session.shared.inviteCode = "21790-7d53f29b1eaca0bdc5bd6ad24b8f4e1c"
        Applet.Session.shared.appletActivationRedirect = URL(string: "ifttt-api-example://sdk-callback")!
        Applet.Session.shared.userTokenProvider = IFTTTAuthenication.shared
        
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.backgroundColor = .white
        window.rootViewController = LoginViewController()
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

/// Mock device keychain store
class KeychainMock {
    static let shared = KeychainMock()
    
    private var storage = [String : String]()
    
    subscript(key: String) -> String? {
        get {
            return storage[key]
        }
        set {
            storage[key] = newValue
        }
    }
}

struct IFTTTAuthenication: UserTokenProviding {
    static let shared = IFTTTAuthenication()
    
    let keychain = KeychainMock.shared
    
    func apiExampleOauthToken(_ token: String) {
        keychain["my_user_token"] = token
    }
    func partnerOauthTokenForServiceConnection(_ session: Applet.Session) -> String {
        return keychain["my_user_token"] ?? ""
    }
    
    func setIftttUserToken(_ token: String?) {
        keychain["ifttt_user_token"] = token
    }
    func iftttUserToken(for session: Applet.Session) -> String? {
        return keychain["ifttt_user_token"]
    }
}
