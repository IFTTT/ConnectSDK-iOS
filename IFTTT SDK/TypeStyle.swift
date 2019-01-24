//
//  Typestyle.swift
//  IFTTT SDK
//
//  Created by Jon Chmura on 9/28/18.
//  Copyright © 2018 IFTTT. All rights reserved.
//

import UIKit

@available(iOS 10.0, *)

/// A structure that handles `UIFont` configuration for the application.
struct TypeStyle: Equatable {
    
    /// The weight options available to `TypeStyle` fonts.
    enum Weight: String {
        
        /// A font with the heavy weight.
        case heavy = "Heavy"
        
        /// A font with the bold weight.
        case bold = "Bold"
        
        /// A font with the demi bold weight.
        case demiBold = "DemiBold"
        
        /// A font with the medium weight.
        case medium = "Medium"
    }
    
    /// The thickness of the font.
    let weight: Weight
    
    /// The size of the text.
    let size: CGFloat
    
    /// Whether the font scales based on a user's settings.
    let isDynamic: Bool
    
    /// The preferred style to use for the font.
    let style: UIFont.TextStyle
    
    /// The name of the font.
    var name: String {
        return "AvenirNext-\(weight.rawValue)"
    }
    
    /// The `Typestyle` converted to a `UIFont`.
    var font: UIFont {
        let font = UIFont(name: name, size: size)!
        if #available(iOS 11, *), isDynamic {
            return style.metrics.scaledFont(for: font)
        }
        return font
    }
    
    /// Creates the header 1 `Typestyle`.
    ///
    /// - Parameters:
    ///   - weight: The thickness of the font. Defaults to bold.
    ///   - isDynamic: Whether the font scales based on a user's settings. Defaults to true.
    ///   - isCallout: Whether the font style should be set to `.callout`. Defaults to false.
    /// - Returns: The `Typestyle` configured.
    static func h1(weight: Weight = .bold, isDynamic: Bool = true, isCallout: Bool = false) -> TypeStyle {
        if #available(iOS 11, *) {
            let style: UIFont.TextStyle = isCallout == true ? .callout : .largeTitle
            return TypeStyle(weight: weight, size: 36, isDynamic: isDynamic, style: style)
        } else {
            let style: UIFont.TextStyle = isCallout == true ? .callout : .title1
            return TypeStyle(weight: weight, size: 36, isDynamic: isDynamic, style: style)
        }
    }
    
    /// Creates the header 2 `Typestyle`.
    ///
    /// - Parameters:
    ///   - weight: The thickness of the font. Defaults to bold.
    ///   - isDynamic: Whether the font scales based on a user's settings. Defaults to true.
    ///   - isCallout: Whether the font style should be set to `.callout`. Defaults to false.
    /// - Returns: The `Typestyle` configured.
    static func h2(weight: Weight = .bold, isDynamic: Bool = true, isCallout: Bool = false) -> TypeStyle {
        let style: UIFont.TextStyle = isCallout == true ? .callout : .title1
        return TypeStyle(weight: weight, size: 30, isDynamic: isDynamic, style: style)
    }
    
    /// Creates the header 3 `Typestyle`.
    ///
    /// - Parameters:
    ///   - weight: The thickness of the font. Defaults to bold.
    ///   - isDynamic: Whether the font scales based on a user's settings. Defaults to true.
    ///   - isCallout: Whether the font style should be set to `.callout`. Defaults to false.
    /// - Returns: The `Typestyle` configured.
    static func h3(weight: Weight = .bold, isDynamic: Bool = true, isCallout: Bool = false) -> TypeStyle {
        let style: UIFont.TextStyle = isCallout == true ? .callout : .title2
        return TypeStyle(weight: weight, size: 28, isDynamic: isDynamic, style: style)
    }
    
    /// Creates the header 4 `Typestyle`.
    ///
    /// - Parameters:
    ///   - weight: The thickness of the font. Defaults to bold.
    ///   - isDynamic: Whether the font scales based on a user's settings. Defaults to true.
    ///   - isCallout: Whether the font style should be set to `.callout`. Defaults to false.
    /// - Returns: The `Typestyle` configured.
    static func h4(weight: Weight = .bold, isDynamic: Bool = true, isCallout: Bool = false) -> TypeStyle {
        let style: UIFont.TextStyle = isCallout == true ? .callout : .title3
        return TypeStyle(weight: weight, size: 24, isDynamic: isDynamic, style: style)
    }
    
    /// Creates the header 5 `Typestyle`.
    ///
    /// - Parameters:
    ///   - weight: The thickness of the font. Defaults to bold.
    ///   - isDynamic: Whether the font scales based on a user's settings. Defaults to true.
    ///   - isCallout: Whether the font style should be set to `.callout`. Defaults to false.
    /// - Returns: The `Typestyle` configured.
    static func h5(weight: Weight = .bold, isDynamic: Bool = true, isCallout: Bool = false) -> TypeStyle {
        let style: UIFont.TextStyle = isCallout == true ? .callout : .headline
        return TypeStyle(weight: weight, size: 20, isDynamic: isDynamic, style: style)
    }
    
    /// Creates the header 6 `Typestyle`.
    ///
    /// - Parameters:
    ///   - weight: The thickness of the font. Defaults to bold.
    ///   - isDynamic: Whether the font scales based on a user's settings. Defaults to true.
    ///   - isCallout: Whether the font style should be set to `.callout`. Defaults to false.
    /// - Returns: The `Typestyle` configured.
    static func h6(weight: Weight = .bold, isDynamic: Bool = true, isCallout: Bool = false) -> TypeStyle {
        let style: UIFont.TextStyle = isCallout == true ? .callout : .subheadline
        return TypeStyle(weight: weight, size: 18, isDynamic: isDynamic, style: style)
    }
    
    /// Creates the body `Typestyle`.
    ///
    /// - Parameters:
    ///   - weight: The thickness of the font. Defaults to medium.
    ///   - isDynamic: Whether the font scales based on a user's settings. Defaults to true.
    ///   - isCallout: Whether the font style should be set to `.callout`. Defaults to false.
    /// - Returns: The `Typestyle` configured.
    static func body(weight: Weight = .medium, isDynamic: Bool = true, isCallout: Bool = false) -> TypeStyle {
        let style: UIFont.TextStyle = isCallout == true ? .callout : .body
        return TypeStyle(weight: weight, size: 16, isDynamic: isDynamic, style: style)
    }
    
    /// Creates the footnote `Typestyle`.
    ///
    /// - Parameters:
    ///   - weight: The thickness of the font. Defaults to medium.
    ///   - isDynamic: Whether the font scales based on a user's settings. Defaults to true.
    ///   - isCallout: Whether the font style should be set to `.callout`. Defaults to false.
    /// - Returns: The `Typestyle` configured.
    static func footnote(weight: Weight = .medium, isDynamic: Bool = true, isCallout: Bool = false) -> TypeStyle {
        let style: UIFont.TextStyle = isCallout == true ? .callout : .footnote
        return TypeStyle(weight: weight, size: 14, isDynamic: isDynamic, style: style)
    }
    
    /// Creates the caption `Typestyle`.
    ///
    /// - Parameters:
    ///   - weight: The thickness of the font. Defaults to medium.
    ///   - isDynamic: Whether the font scales based on a user's settings. Defaults to true.
    ///   - isCallout: Whether the font style should be set to `.callout`. Defaults to false.
    /// - Returns: The `Typestyle` configured.
    static func caption(weight: Weight = .medium, isDynamic: Bool = true, isCallout: Bool = false) -> TypeStyle {
        let style: UIFont.TextStyle = isCallout == true ? .callout : .caption1
        return TypeStyle(weight: weight, size: 12, isDynamic: isDynamic, style: style)
    }
    
    /// Creates the small `Typestyle`.
    ///
    /// - Parameters:
    ///   - weight: The thickness of the font. Defaults to bold.
    ///   - isDynamic: Whether the font scales based on a user's settings. Defaults to true.
    ///   - isCallout: Whether the font style should be set to `.callout`. Defaults to false.
    /// - Returns: The `Typestyle` configured.
    static func small(weight: Weight = .bold, isDynamic: Bool = true, isCallout: Bool = false) -> TypeStyle {
        let style: UIFont.TextStyle = isCallout == true ? .callout : .caption2
        return TypeStyle(weight: weight, size: 10, isDynamic: isDynamic, style: style)
    }
}
