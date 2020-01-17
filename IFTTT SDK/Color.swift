//
//  Color.swift
//  IFTTT SDK
//
//  Copyright © 2019 IFTTT. All rights reserved.
//

import UIKit

extension UIColor {
    var hsba: [CGFloat]? {
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        if getHue(&h, saturation: &s, brightness: &b, alpha: &a) {
            return [h, s, b, a]
        }
        return nil
    }
    
    /// Option type defining each color component in HSBA
    struct HSBA: OptionSet {
        let rawValue: Int
        
        static let h = HSBA(rawValue: 1 << 0)
        static let s = HSBA(rawValue: 1 << 1)
        static let b = HSBA(rawValue: 1 << 2)
        static let a = HSBA(rawValue: 1 << 2)
        
        static let all: HSBA = [.h, .s, .b, .a]
    }
    
    /// Returns the distance between the 2 colors where 0 is the same color and 1 is completely different (ie. white v. black)
    func distance(from otherColor: UIColor, comparing: HSBA = .all) -> CGFloat {
        guard self != otherColor else {
            return 0
        }
        guard let hsba = self.hsba, let otherHsba = otherColor.hsba else {
            return 1
        }
        var value: CGFloat = 0
        if comparing.contains(.h) {
            value += pow(hsba[0] - otherHsba[0], 2)
        }
        if comparing.contains(.s) {
            value += pow(hsba[1] - otherHsba[1], 2)
        }
        if comparing.contains(.b) {
            value += pow(hsba[2] - otherHsba[2], 2)
        }
        if comparing.contains(.a) {
            value += pow(hsba[3] - otherHsba[3], 2)
        }
        return sqrt(value)
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
        
        var value: UInt32 = 0
        Scanner(string: trimmed).scanHexInt32(&value)
        self.init(hex: value)
    }
    
    convenience init(hex: UInt32) {
        let r = (hex & 0xff0000) >> 16
        let g = (hex & 0xff00) >> 8
        let b = hex & 0xff
        
        self.init(
            red: CGFloat(r) / 0xff,
            green: CGFloat(g) / 0xff,
            blue: CGFloat(b) / 0xff, alpha: 1
        )
    }
    
    var hex: UInt32 {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        self.getRed(&r, green: &g, blue: &b, alpha: nil)
        
        var value = UInt32(r * 0xff) << 16
        value = value | (UInt32(g * 0xff) << 8)
        value = value | UInt32(b * 0xff)
        return value
    }
}
