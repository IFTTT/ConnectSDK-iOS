//
//  AppDelegate.swift
//  SDK Example
//
//  Created by Jon Chmura on 8/31/18.
//  Copyright © 2018 IFTTT. All rights reserved.
//

import UIKit
import IFTTT_SDK

// Test using the SDK with an email address
// This is a required property in `ConnectionConfiguration`
// In a real app, this would be the email address of your signed in user
var ExampleUserEmail = "jon-test1124"

/// Add style. Tests connect button on light and dark apps
enum Style {
    case light
    case dark
    
    static var currentStyle: Style = Bool.random() ? .light : .dark
    
    var foregroundColor: UIColor {
        switch self {
        case .light: return .black
        case .dark: return .white
        }
    }
    
    var backgroundColor: UIColor {
        switch self {
        case .light: return .white
        case .dark: return .black
        }
    }
}

class NavigationController: UINavigationController {
    
    override func loadView() {
        super.loadView()
        
        navigationBar.barTintColor = Style.currentStyle.backgroundColor
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        switch Style.currentStyle {
        case .light:
            return .default
        case .dark:
            return .lightContent
        }
    }
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    static var shared: AppDelegate?
    
    var window: UIWindow?
    
    static let connectionRedirectURL = URL(string: "ifttt-api-example://sdk-callback")!
    private let connectionRedirectHandler = AuthenticationRedirectHandler(authorizationRedirectURL: AppDelegate.connectionRedirectURL)
    
    func login() {
        window?.rootViewController = NavigationController(rootViewController: HomeViewController())
    }
    
    @objc func swapStyle() {
        Style.currentStyle = Style.currentStyle == .light ? .dark : .light
        login()
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        AppDelegate.shared = self
        
        IFTTTAuthenication.shared.setIftttUserToken(nil)
        
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.backgroundColor = .white
        window.rootViewController = LoginViewController()
        window.makeKeyAndVisible()
        self.window = window
        
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

struct IFTTTAuthenication: CredentialProvider {
    static let shared = IFTTTAuthenication()
    
    let keychain = KeychainMock.shared
    
    var partnerOAuthCode: String {
        return keychain["my_user_token"] ?? ""
    }
    
    var iftttServiceToken: String? {
        return keychain["ifttt_user_token"]
    }
    
    var inviteCode: String? {
        return "21790-7d53f29b1eaca0bdc5bd6ad24b8f4e1c"
    }
    
    func apiExampleOauthToken(_ token: String) {
        keychain["my_user_token"] = token
    }
    
    func setIftttUserToken(_ token: String?) {
        keychain["ifttt_user_token"] = token
    }
}
