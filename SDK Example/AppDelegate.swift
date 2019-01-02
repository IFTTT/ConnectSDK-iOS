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
    
    static var shared: AppDelegate?
    
    static let connectionRedirectURL = URL(string: "groceryexpress://connect_callback")!
    
    private let connectionRedirectHandler = AuthenticationRedirectHandler(authorizationRedirectURL: AppDelegate.connectionRedirectURL)
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        AppDelegate.shared = self
        
        IFTTTAuthenication.shared.setIftttUserToken(nil)
        
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

/// Mock device keychain store
class KeychainMock {
    subscript(key: String) -> String? {
        get {
            return UserDefaults.standard.string(forKey: key)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: key)
        }
    }
}

struct IFTTTAuthenication: CredentialProvider {
    static let shared = IFTTTAuthenication()
    
    let keychain = KeychainMock()
    
    var partnerOAuthCode: String {
        return keychain["my_user_token"] ?? ""
    }
    
    var iftttServiceToken: String? {
        return keychain["ifttt_user_token"]
    }
    
    var inviteCode: String? {
        return "213621-90a10d229fbf8177a7ba0e6249847daf"
    }
    
    func apiExampleOauthToken(_ token: String) {
        keychain["my_user_token"] = token
    }
    
    func setIftttUserToken(_ token: String?) {
        keychain["ifttt_user_token"] = token
    }
}
