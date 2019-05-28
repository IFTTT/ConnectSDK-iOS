//
//  ConnectButton+Constants.swift
//  IFTTT SDK
//
//  Created by Michael Amundsen on 5/23/19.
//  Copyright © 2019 IFTTT. All rights reserved.
//

import Foundation

@available(iOS 10.0, *)
extension ConnectButton {
    
    // Layout constants
    struct Layout {
        static let height: CGFloat = 70
        static let maximumWidth = 4.7 * height
        static let knobInset: CGFloat = borderWidth + 3
        static let knobDiameter = height - 2 * knobInset
        static let checkmarkDiameter: CGFloat = 42
        static let checkmarkLength: CGFloat = 14
        static let serviceIconDiameter = 0.5 * knobDiameter
        
        /// The thickness of the border around the the connect button.
        static let borderWidth: CGFloat = 4
        
        /// The amount by which the email field is offset from the center
        static let emailFieldOffset: CGFloat = 4
        static let buttonFooterSpacing: CGFloat = 15
    }
    
    struct Color {
        static let blue = UIColor(hex: 0x0099FF)
        static let lightGrey = UIColor(hex: 0xCCCCCC)
        static let mediumGrey = UIColor(hex: 0x666666)
        static let grey = UIColor(hex: 0x414141)
        static let border = UIColor(white: 1, alpha: 0.32)
    }
}