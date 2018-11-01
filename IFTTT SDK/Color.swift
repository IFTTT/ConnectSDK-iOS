//
//  Color.swift
//  IFTTT SDK
//
//  Created by Jon Chmura on 9/28/18.
//  Copyright © 2018 IFTTT. All rights reserved.
//

import UIKit

extension UIColor {
    static var iftttBlack = UIColor(hex: 0x222222)
    static var iftttBlue = UIColor(hex: 0x0099FF)
    static var iftttOrange = UIColor(hex: 0xEE4433)
    static var iftttLightGrey = UIColor(hex: 0xCCCCCC)
    static var iftttGrey = UIColor(hex: 0x414141)
    static var iftttBorderColor = UIColor(white: 1, alpha: 0.2)
    
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
