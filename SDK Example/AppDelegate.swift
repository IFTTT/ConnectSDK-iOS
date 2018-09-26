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
        
        Applet.Session.shared.serviceId = "google_calendar"
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
