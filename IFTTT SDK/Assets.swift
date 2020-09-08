//
//  Assets.swift
//  IFTTT SDK
//
//  Copyright © 2019 IFTTT. All rights reserved.
//

import UIKit

struct Assets {
    struct Button {
        static let emailConfirm = UIImage.iftttAsset(named: "ifttt_email_confirm")
    }
    struct About {
        static let connectArrow = UIImage.iftttAsset(named: "ifttt_about_connect_arrow")
        static let connect = UIImage.iftttAsset(named: "ifttt_about_connect")
        static let control = UIImage.iftttAsset(named: "ifttt_about_control")
        static let security = UIImage.iftttAsset(named: "ifttt_about_security")
        static let manage = UIImage.iftttAsset(named: "ifttt_about_unplug")
        static let close = UIImage.iftttAsset(named: "ifttt_about_close")
        static let downloadOnAppStore = UIImage.iftttAsset(named: "ifttt_about_download_on_app_store")
    }
}

private extension UIImage {
    static func iftttAsset(named: String) -> UIImage? {
        return UIImage(named: named, in: Bundle.sdk, compatibleWith: nil)
    }
}
