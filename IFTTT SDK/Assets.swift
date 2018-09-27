//
//  Assets.swift
//  IFTTT SDK
//
//  Created by Jon Chmura on 9/27/18.
//  Copyright © 2018 IFTTT. All rights reserved.
//

import UIKit

extension Bundle {
    static var sdk: Bundle {
        return Bundle(for: ConnectButton.self)
    }
}

struct Assets {
    struct Button {
        static let emailConfirm = UIImage.iftttAsset(named: "email_confirm")
    }
}

private extension UIImage {
    static func iftttAsset(named: String) -> UIImage {
        return UIImage(named: named, in: Bundle.sdk, compatibleWith: nil)!
    }
}

extension String {
    static func localized(_ key: String) -> String {
        // FIXME: Struggling with strings file. Doing this for now.
        let strings = [
            "connect_button.connect_service" : "Connect",
            "connect_button.email.placeholder" : "Your email",
            "connect_button.footer.powered_by" : "POWERED BY IFTTT",
            "connect_button.footer.email" : "Enter your email address to Authorize IFTTT",
            "connect_button.footer.manage" : "Manage connection with IFTTT",
            
            "about.title" : "This connection is powered by IFTTT",
            "about.control_information" : "Control what services get your information",
            "about.toggle_access" : "Turn on and off access to specific services",
            "about.security" : "Stay secure with end-to-end encryption",
            "about.unlock_products" : "Unlock connections to hundreds of other products",
            "about.more.button" : "More about IFTTT",
            ]
        return strings[key]!
    }
}
