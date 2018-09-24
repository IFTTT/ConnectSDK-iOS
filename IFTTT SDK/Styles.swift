//
//  Styles.swift
//  IFTTT SDK
//
//  Created by Jon Chmura on 9/17/18.
//  Copyright © 2018 IFTTT. All rights reserved.
//

import UIKit

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

extension UILabel {
    convenience init(_ text: String, style: UIFont.Style, color: UIColor = .iftttBlack, alignment: NSTextAlignment = .left) {
        self.init()
        
        self.text = text
        font = .ifttt(style)
        textColor = color
        numberOfLines = 0
        textAlignment = alignment
    }
}

extension UIStackView {
    static func vertical(_ views: [UIView], spacing: CGFloat, alignment: UIStackView.Alignment) -> UIStackView {
        let view = UIStackView(arrangedSubviews: views)
        view.axis = .vertical
        view.spacing = spacing
        view.alignment = alignment
        return view
    }
}

extension UIColor {
    static var iftttBlack = UIColor(hex: 0x222222)
    static var iftttBlue = UIColor(hex: 0x0099FF)
    static var iftttLightGrey = UIColor(hex: 0xCCCCCC)
    static var iftttGrey = UIColor(hex: 0x414141)
    
    var hsba: [CGFloat]? {
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        if getHue(&h, saturation: &s, brightness: &b, alpha: &a) {
            return [h, s, b, a]
        }
        return nil
    }
    
    /// Get the constrast color for a primary color
    /// Dark colors are brightened and light colors are darkened
    /// Optionally specify a ratio for brightening and darkening amount
    /// Default values are 0.08 and 0.15 respectively
    func contrasting(brighteningAdjustment: CGFloat = 0.08, darkeningAdjustment: CGFloat = 0.15) -> UIColor {
        guard let hsba = self.hsba else { return self }
        var bright = hsba[2]
        
        if bright < 0.25 {
            bright += brighteningAdjustment
        } else {
            bright -= darkeningAdjustment
        }
        return UIColor(hue: hsba[0], saturation: hsba[1], brightness: max(0, min(1, bright)), alpha: hsba[3])
    }
    
    convenience init(hex: String) {
        var charSet = CharacterSet.whitespacesAndNewlines
        charSet.insert("#")
        
        let trimmed = hex.trimmingCharacters(in: charSet)
        
        guard trimmed.count == 6 else {
            self.init(white: 0, alpha: 1)
            return
        }
        
        var value: UInt64 = 0
        Scanner(string: trimmed).scanHexInt64(&value)
        self.init(hex: value)
    }
    
    convenience init(hex: UInt64) {
        let r = (hex & 0xff0000) >> 16
        let g = (hex & 0xff00) >> 8
        let b = hex & 0xff
        
        self.init(
            red: CGFloat(r) / 0xff,
            green: CGFloat(g) / 0xff,
            blue: CGFloat(b) / 0xff, alpha: 1
        )
    }
}

private extension UIFont.Weight {
    var name: String {
        switch self {
        case .heavy:
            return "Heavy"
        case .bold:
            return "Bold"
        default:
            return "Medium"
        }
    }
}

extension UIFont {
    static let BaseFont = "AvenirNext"
    
    enum Style {
        case
        wordmark(size: CGFloat),
        headline,
        body,
        callout,
        footnoteBold,
        footnote
    }
    
    static func ifttt(_ style: Style, isDynamic: Bool = true) -> UIFont {
        let font: UIFont = {
            switch style {
            case .wordmark(let size):
                return .ifttt(weight: .heavy, size: size)
            case .headline:
                return .ifttt(weight: .bold, size: 20)
            case .body:
                return .ifttt(weight: .medium, size: 16)
            case .callout:
                return .ifttt(weight: .bold, size: 20)
            case .footnoteBold:
                return .ifttt(weight: .bold, size: 14)
            case .footnote:
                return .ifttt(weight: .medium, size: 14)
            }
        }()
        if #available(iOS 11, *) {
            switch style {
            case .wordmark:
                return .scaledFont(.title1, font: font)
            case .headline:
                return .scaledFont(.headline, font: font)
            case .body:
                return .scaledFont(.body, font: font)
            case .callout:
                return .scaledFont(.callout, font: font)
            case .footnoteBold:
                return .scaledFont(.footnote, font: font)
            case .footnote:
                return .scaledFont(.footnote, font: font)
            }
        } else {
            return font
        }
    }
    
    @available(iOS 11.0, *)
    private static func scaledFont(_ style: TextStyle, font: UIFont) -> UIFont {
        return style.metrics.scaledFont(for: font)
    }
    
    private static func ifttt(weight: Weight, size: CGFloat) -> UIFont {
        let name = "\(BaseFont)-\(weight.name)"
        return UIFont(name: name, size: size)!
    }
}
