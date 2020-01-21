//
//  ConnectButton+Style.swift
//  IFTTT SDK
//
//  Copyright © 2019 IFTTT. All rights reserved.
//

import Foundation

extension ConnectButton {
    
    /// Adjusts the button for a white or black background
    ///
    /// - light: Style the button for a white background
    public enum Style {
        
        /// Style the button for a white background
        case light
        
        struct Font {
            static let connect = UIFont(name: "AvenirNext-Bold", size: 22)!
            static let email = UIFont(name: "AvenirNext-DemiBold", size: 18)!
        }
        
        /// The color to use for the footer based on the style.
        var footerColor: UIColor {
            switch self {
            case .light:
                return lightColorFooter()
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
