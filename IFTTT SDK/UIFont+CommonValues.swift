//
//  Typestyle.swift
//  IFTTT SDK
//
//  Copyright © 2019 IFTTT. All rights reserved.
//

import UIKit

extension UIFont {
    
    /// The weight options available for the app's custom fonts.
    enum CustomFontWeight: String {
        
        /// A font with the heavy weight.
        case heavy = "Heavy"
        
        /// A font with the bold weight.
        case bold = "Bold"
        
        /// A font with the demi bold weight.
        case demiBold = "DemiBold"
        
        /// A font with the medium weight.
        case medium = "Medium"
    }
    
    private static func customFontName(withWeight weight: CustomFontWeight) -> String {
        return "AvenirNext-\(weight.rawValue)"
    }
    
    private static func customFont(withName name: String, size: CGFloat, style: UIFont.TextStyle, isDynamic: Bool) -> UIFont {
        let font = UIFont(name: name, size: size)!
        
        if #available(iOS 11, *), isDynamic {
            return style.metrics.scaledFont(for: font)
        }
        
        return font
    }
    
    /// Creates the header 1 font.
    ///
    /// - Parameters:
    ///   - weight: The thickness of the font. Defaults to bold.
    ///   - isDynamic: Whether the font scales based on a user's settings. Defaults to true.
    ///   - isCallout: Whether the font style should be set to `.callout`. Defaults to false.
    /// - Returns: The font configured.
    static func h1(weight: CustomFontWeight = .bold, isDynamic: Bool = true, isCallout: Bool = false) -> UIFont {
        let name = customFontName(withWeight: weight)
        let style: UIFont.TextStyle
        
        if #available(iOS 11, *) {
            style = isCallout == true ? .callout : .largeTitle
        } else {
            style = isCallout == true ? .callout : .title1
        }
        
        return customFont(withName: name, size: 36, style: style, isDynamic: isDynamic)
    }
    
    /// Creates the header 2 font.
    ///
    /// - Parameters:
    ///   - weight: The thickness of the font. Defaults to bold.
    ///   - isDynamic: Whether the font scales based on a user's settings. Defaults to true.
    ///   - isCallout: Whether the font style should be set to `.callout`. Defaults to false.
    /// - Returns: The font configured.
    static func h2(weight: CustomFontWeight = .bold, isDynamic: Bool = true, isCallout: Bool = false) -> UIFont {
        let name = customFontName(withWeight: weight)
        let style: UIFont.TextStyle = isCallout == true ? .callout : .title1
        
        return customFont(withName: name, size: 30, style: style, isDynamic: isDynamic)
    }
    
    /// Creates the header 3 font.
    ///
    /// - Parameters:
    ///   - weight: The thickness of the font. Defaults to bold.
    ///   - isDynamic: Whether the font scales based on a user's settings. Defaults to true.
    ///   - isCallout: Whether the font style should be set to `.callout`. Defaults to false.
    /// - Returns: The font configured.
    static func h3(weight: CustomFontWeight = .bold, isDynamic: Bool = true, isCallout: Bool = false) -> UIFont {
        let name = customFontName(withWeight: weight)
        let style: UIFont.TextStyle = isCallout == true ? .callout : .title2
        
        return customFont(withName: name, size: 28, style: style, isDynamic: isDynamic)
    }
    
    /// Creates the header 4 font.
    ///
    /// - Parameters:
    ///   - weight: The thickness of the font. Defaults to bold.
    ///   - isDynamic: Whether the font scales based on a user's settings. Defaults to true.
    ///   - isCallout: Whether the font style should be set to `.callout`. Defaults to false.
    /// - Returns: The font configured.
    static func h4(weight: CustomFontWeight = .bold, isDynamic: Bool = true, isCallout: Bool = false) -> UIFont {
        let name = customFontName(withWeight: weight)
        let style: UIFont.TextStyle = isCallout == true ? .callout : .title3
        
        return customFont(withName: name, size: 24, style: style, isDynamic: isDynamic)
    }
    
    /// Creates the header 5 font.
    ///
    /// - Parameters:
    ///   - weight: The thickness of the font. Defaults to bold.
    ///   - isDynamic: Whether the font scales based on a user's settings. Defaults to true.
    ///   - isCallout: Whether the font style should be set to `.callout`. Defaults to false.
    /// - Returns: The font configured.
    static func h5(weight: CustomFontWeight = .bold, isDynamic: Bool = true, isCallout: Bool = false) -> UIFont {
        let name = customFontName(withWeight: weight)
        let style: UIFont.TextStyle = isCallout == true ? .callout : .headline
        
        return customFont(withName: name, size: 20, style: style, isDynamic: isDynamic)
    }
    
    /// Creates the header 6 font.
    ///
    /// - Parameters:
    ///   - weight: The thickness of the font. Defaults to bold.
    ///   - isDynamic: Whether the font scales based on a user's settings. Defaults to true.
    ///   - isCallout: Whether the font style should be set to `.callout`. Defaults to false.
    /// - Returns: The font configured.
    static func h6(weight: CustomFontWeight = .bold, isDynamic: Bool = true, isCallout: Bool = false) -> UIFont {
        let name = customFontName(withWeight: weight)
        let style: UIFont.TextStyle = isCallout == true ? .callout : .subheadline
        
        return customFont(withName: name, size: 18, style: style, isDynamic: isDynamic)
    }
    
    /// Creates the body font.
    ///
    /// - Parameters:
    ///   - weight: The thickness of the font. Defaults to medium.
    ///   - isDynamic: Whether the font scales based on a user's settings. Defaults to true.
    ///   - isCallout: Whether the font style should be set to `.callout`. Defaults to false.
    /// - Returns: The font configured.
    static func body(weight: CustomFontWeight = .medium, isDynamic: Bool = true, isCallout: Bool = false) -> UIFont {
        let name = customFontName(withWeight: weight)
        let style: UIFont.TextStyle = isCallout == true ? .callout : .body
        
        return customFont(withName: name, size: 16, style: style, isDynamic: isDynamic)
    }
    
    /// Creates the standard callout font
    /// This is equivalent to body with demi bold weight and isCallout == true
    ///
    /// - Parameters:
    ///   - weight: The thickness of the font. Defaults to demi bold.
    ///   - isDynamic: Whether the font scales based on a user's settings. Defaults to true.
    /// - Returns: The font configured.
    static func callout(weight: CustomFontWeight = .demiBold, isDynamic: Bool = true) -> UIFont {
        return .body(weight: weight, isDynamic: isDynamic, isCallout: true)
    }
    
    /// Creates the footnote font.
    ///
    /// - Parameters:
    ///   - weight: The thickness of the font. Defaults to medium.
    ///   - isDynamic: Whether the font scales based on a user's settings. Defaults to true.
    ///   - isCallout: Whether the font style should be set to `.callout`. Defaults to false.
    /// - Returns: The font configured.
    static func footnote(weight: CustomFontWeight = .medium, isDynamic: Bool = true, isCallout: Bool = false) -> UIFont {
        let name = customFontName(withWeight: weight)
        let style: UIFont.TextStyle = isCallout == true ? .callout : .footnote
        
        return customFont(withName: name, size: 14, style: style, isDynamic: isDynamic)
    }
    
    /// Creates the caption font.
    ///
    /// - Parameters:
    ///   - weight: The thickness of the font. Defaults to medium.
    ///   - isDynamic: Whether the font scales based on a user's settings. Defaults to true.
    ///   - isCallout: Whether the font style should be set to `.callout`. Defaults to false.
    /// - Returns: The font configured.
    static func caption(weight: CustomFontWeight = .medium, isDynamic: Bool = true, isCallout: Bool = false) -> UIFont {
        let name = customFontName(withWeight: weight)
        let style: UIFont.TextStyle = isCallout == true ? .callout : .caption1
        
        return customFont(withName: name, size: 12, style: style, isDynamic: isDynamic)
    }
    
    /// Creates the small font.
    ///
    /// - Parameters:
    ///   - weight: The thickness of the font. Defaults to bold.
    ///   - isDynamic: Whether the font scales based on a user's settings. Defaults to true.
    ///   - isCallout: Whether the font style should be set to `.callout`. Defaults to false.
    /// - Returns: The font configured.
    static func small(weight: CustomFontWeight = .bold, isDynamic: Bool = true, isCallout: Bool = false) -> UIFont {
        let name = customFontName(withWeight: weight)
        let style: UIFont.TextStyle = isCallout == true ? .callout : .caption2
        
        return customFont(withName: name, size: 10, style: style, isDynamic: isDynamic)
    }
    
}
