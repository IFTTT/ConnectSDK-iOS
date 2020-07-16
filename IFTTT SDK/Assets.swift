//
//  Assets.swift
//  IFTTT SDK
//
//  Copyright © 2019 IFTTT. All rights reserved.
//

import UIKit

extension Bundle {
    private static let ResourceName = "IFTTTConnectSDK"
    private static let BundleExtensionName = "bundle"
    
    static var sdk: Bundle {
        let connectButtonBundle = Bundle(for: ConnectButton.self)
        guard let urlForBundle = connectButtonBundle.url(forResource: ResourceName, withExtension: BundleExtensionName),
            let bundle = Bundle(url: urlForBundle) else {
                // If we're unable to generate the bundle indicated by `ResourceName`, fall back to returning the bundle for the `ConnectButton` instead.
                return connectButtonBundle
        }
        
        return bundle
    }
    
    var appName: String? {
        return object(forInfoDictionaryKey: "CFBundleName") as? String
    }
}

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
