//
//  LegalText.swift
//  IFTTT SDK
//
//  Created by Jon Chmura on 12/14/18.
//  Copyright © 2018 IFTTT. All rights reserved.
//

import Foundation

/// Factory for building `NSAttributedString` with links for Terms of Use and our Privacy Policy
@available(iOS 10.0, *)
struct LegalTermsText {
    
    private static let termsOfService = "legal.tos".localized
    
    private static let joinText = "legal.and".localized
    
    private static let privacyPolicy = "legal.privacy".localized
    
    /// Creates a string with links to IFTTT's terms of service and privacy policy
    /// Prefix text is added before the links in the format "[prefix text] Terms_of_Use and Privacy_Policy"
    ///
    /// - Parameter prefix: The prefix before the links
    /// - Returns: The constructed `NSAttributedString`
    static func string(withPrefix prefix: String, attributes: [NSAttributedString.Key : Any]) -> NSAttributedString {
        let text = NSMutableAttributedString(string: prefix, attributes: attributes)
        
        text.addLink(text: termsOfService, to: Links.termsOfService, attributes: attributes)
        text.append(NSAttributedString(string: joinText, attributes: attributes))
        text.addLink(text: privacyPolicy, to: Links.privacyPolicy, attributes: attributes)
        
        return NSAttributedString(attributedString: text)
    }
}

private extension NSMutableAttributedString {
    
    /// Adds a link to a url for a text snippet
    ///
    /// - Parameters:
    ///   - text: The text for the link
    ///   - url: The URL to link to
    func addLink(text: String, to url: URL, attributes: [NSAttributedString.Key : Any]) {
        append(NSAttributedString(string: text, attributes: attributes))
        
        let range = mutableString.range(of: text)
        assert(range.location != NSNotFound, "This should never happen but if it does, the `text` may include some special characters.")
        if range.location != NSNotFound {
            addAttribute(.link, value: url.absoluteString, range: range)
            addAttributes(attributes, range: range)
            addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: range)
        }
    }
}
