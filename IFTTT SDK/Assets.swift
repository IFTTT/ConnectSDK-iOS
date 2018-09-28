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
    struct About {
        static let ifttt = UIImage.iftttAsset(named: "about_ifttt")
        static let connect = UIImage.iftttAsset(named: "about_connect")
        static let control = UIImage.iftttAsset(named: "about_control")
        static let manage = UIImage.iftttAsset(named: "about_manage")
        static let security = UIImage.iftttAsset(named: "about_security")
    }
}

private extension UIImage {
    static func iftttAsset(named: String) -> UIImage {
        return UIImage(named: named, in: Bundle.sdk, compatibleWith: nil)!
    }
}

extension String {
    func localized(arguments: CVarArg) -> String {
        return String(format: self.localized, arguments)
    }
    var localized: String {
        return NSLocalizedString(self, tableName: nil, bundle: Bundle.sdk, value: "", comment: "")
    }
}
