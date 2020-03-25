//
//  Assets.swift
//  IFTTT SDK
//
//  Copyright © 2019 IFTTT. All rights reserved.
//

import UIKit

struct Assets {
    struct Button {
        static let emailConfirm = UIImage.iftttAsset(named: "email_confirm")
    }
    struct About {
        static let connectArrow = UIImage.iftttAsset(named: "about_connect_arrow")
        static let connect = UIImage.iftttAsset(named: "about_connect")
        static let control = UIImage.iftttAsset(named: "about_control")
        static let security = UIImage.iftttAsset(named: "about_security")
        static let manage = UIImage.iftttAsset(named: "about_unplug")
        static let close = UIImage.iftttAsset(named: "about_close")
        static let downloadOnAppStore = UIImage.iftttAsset(named: "about_download_on_app_store")
    }
}

private extension UIImage {
    static func iftttAsset(named: String) -> UIImage {
        return UIImage(named: named, in: Bundle.sdk, compatibleWith: nil)!
    }
}
