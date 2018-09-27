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
        
        User.current.suggestedUserEmail = "jon@ifttt.com"
        
        Applet.Session.shared.serviceId = "ifttt_api_example"
        Applet.Session.shared.inviteCode = "21790-7d53f29b1eaca0bdc5bd6ad24b8f4e1c"
        Applet.Session.shared.appletActivationRedirect = URL(string: "ifttt-api-example://sdk-callback")!
        Applet.Session.shared.userTokenProvider = IFTTTAuthenication()
        
        return true
    }
}

struct IFTTTAuthenication: UserTokenProviding {
    func iftttUserToken(for session: Applet.Session) -> String? {
        let keychain = Keychain(service: "com.ifttt")
        return keychain["user_token"]
    }
}
