//
//  Typography.swift
//  IFTTT SDK
//
//  Created by Jon Chmura on 9/28/18.
//  Copyright © 2018 IFTTT. All rights reserved.
//

import UIKit

@available(iOS 10.0, *)
extension UIFont {
    static func ifttt(_ typestyle: Typestyle) -> UIFont {
        return typestyle.font
    }
}

@available(iOS 10.0, *)
public struct Typestyle {
    public static var dynamicTypeIsEnabled: Bool = true
    
    public static var dynamicTypeIsSupported: Bool {
        if #available(iOS 11, *) { return true }
        else { return false }
    }
    
    enum Weight: String {
        case
        heavy = "Heavy",
        bold = "Bold",
        demiBold = "DemiBold",
        medium = "Medium"
    }
    
    var name: String {
        return "AvenirNext-\(weight.rawValue)"
    }
    let weight: Weight
    let size: CGFloat
    let isDynamic: Bool
    let style: UIFont.TextStyle
    
    var font: UIFont {
        let font = UIFont(name: name, size: size)!
        if #available(iOS 11, *), isDynamic && Typestyle.dynamicTypeIsEnabled {
            return style.metrics.scaledFont(for: font)
        }
        return font
    }
    
    var nonDynamic: Typestyle {
        return Typestyle(weight: weight, size: size, isDynamic: false, style: style)
    }
    func adjusting(weight: Weight) -> Typestyle {
        return Typestyle(weight: weight, size: size, isDynamic: isDynamic, style: style)
    }
    func callout() -> Typestyle {
        return Typestyle(weight: weight, size: size, isDynamic: isDynamic, style: .callout)
    }
    
    static var h1: Typestyle {
        if #available(iOS 11, *) {
            return Typestyle(weight: .bold, size: 36, isDynamic: true, style: .largeTitle)
        } else {
            return Typestyle(weight: .bold, size: 36, isDynamic: true, style: .title1)
        }
    }
    static var h2: Typestyle {
        return Typestyle(weight: .bold, size: 30, isDynamic: true, style: .title1)
    }
    static var h3: Typestyle {
        return Typestyle(weight: .bold, size: 28, isDynamic: true, style: .title2)
    }
    static var h4: Typestyle {
        return Typestyle(weight: .bold, size: 24, isDynamic: true, style: .title3)
    }
    static var h5: Typestyle {
        return Typestyle(weight: .bold, size: 20, isDynamic: true, style: .headline)
    }
    static var h6: Typestyle {
        return Typestyle(weight: .bold, size: 18, isDynamic: true, style: .subheadline)
    }
    static var body: Typestyle {
        return Typestyle(weight: .medium, size: 16, isDynamic: true, style: .body)
    }
    static var footnote: Typestyle {
        return Typestyle(weight: .medium, size: 14, isDynamic: true, style: .footnote)
    }
    static var caption: Typestyle {
        return Typestyle(weight: .medium, size: 12, isDynamic: true, style: .caption1)
    }
}
