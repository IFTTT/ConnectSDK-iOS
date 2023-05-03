//
//  ConnectButton+Style.swift
//  IFTTT SDK
//
//  Copyright © 2019 IFTTT. All rights reserved.
//

import UIKit

extension ConnectButton {
    
    /// Adjusts the button for a white or black background
    ///
    /// - light: Style the button for a white background
    public enum Style {
        
        /// Style the button for a white background
        case light

        /// Style the button for a dark background
        case dark

        /// Style the button for with dynamic colors:
        /// When the user device is on light mode, the style used is equivalent to `light`.
        /// When on dark mode, the style is equivalent to `dark`.
        ///
        ///  On iOS versions before 13.0, this style is the same as `light`.
        case dynamic
        
        struct Font {
            static let connect = UIFont(name: "AvenirNext-Bold", size: 22)!
            static let email = UIFont(name: "AvenirNext-DemiBold", size: 18)!
        }
        
        /// The color to use for the footer based on the style.
        var footerColor: UIColor {
            return colors(light: lightColorFooter(), dark: Color.lightGrey)
        }

        var buttonBackgroundColor: UIColor {
            return colors(light: Color.almostBlack, dark: .white)
        }

        var textColor: UIColor {
            return colors(light: .white, dark: .black)
        }

        private func colors(light: UIColor, dark: UIColor) -> UIColor {
            switch self {
            case .light:
                return light
            case .dark:
                return dark
            case .dynamic:
                return Color.dynamicColor(light: light, dark: dark)
            }
        }
        
        private func lightColorFooter() -> UIColor {
            return UIColor(white: 0, alpha: 0.32)
        }
        
        private func darkColorFooter() -> UIColor {
            return UIColor(white: 1, alpha: 0.32)
        }
    }
}
