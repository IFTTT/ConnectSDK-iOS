//
//  ConnectButton+Style.swift
//  IFTTT SDK
//
//  Created by Michael Amundsen on 5/23/19.
//  Copyright © 2019 IFTTT. All rights reserved.
//

import Foundation

@available(iOS 10.0, *)
extension ConnectButton {
    
    /// Adjusts the button for a white or black background
    ///
    /// - light: Style the button for a white background (Default)
    /// - dark: Style the button for a black background
    public enum Style {
        
        /// Style the button for a white background (Default)
        case light
        
        /// Style the button for a black background
        case dark
        
        struct Font {
            static let connect = UIFont(name: "AvenirNext-Bold", size: 24)!
            static let email = UIFont(name: "AvenirNext-DemiBold", size: 18)!
        }
        
        /// The color to use for the footer based on the style.
        var footerColor: UIColor {
            switch self {
            case .light:
                return UIColor(white: 0, alpha: 0.32)
            case .dark:
                return UIColor(white: 1, alpha: 0.32)
            }
        }
    }
}
