//
//  LegalText.swift
//  IFTTT SDK
//
//  Copyright © 2019 IFTTT. All rights reserved.
//

import Foundation

/// Factory for building `NSAttributedString` with links for Terms of Use and our Privacy Policy
struct LegalTermsText {
    
    /// Creates a string with links to IFTTT's terms of service and privacy policy
    /// Prefix text is added before the links in the format "[prefix text] Terms_of_Use and Privacy_Policy"
    ///
    /// - Parameters:
    ///     - prefix: The prefix before the links
    ///     - activateLinks: Adds the link attribute, making the links active. Set to false if handling interaction in a custom maner. Default value is true.
    /// - Returns: The constructed `NSAttributedString`
    static func string(withPrefix prefix: String, activateLinks: Bool = true, attributes: [NSAttributedString.Key : Any]) -> NSAttributedString {
        let text = NSMutableAttributedString(string: prefix, attributes: attributes)
        
        text.addLink(text: "about.legal.link".localized,
                     to: Links.privacyAndTerms,
                     activateLinks: activateLinks,
                     attributes: attributes)
        
        return NSAttributedString(attributedString: text)
    }
}

private extension NSMutableAttributedString {
    
    /// Adds a link to a url for a text snippet
    ///
    /// - Parameters:
    ///   - text: The text that have a link added to.
    ///   - activateLinks: Adds the link attribute to the string
    ///   - url: The URL to link to
    func addLink(text: String, to url: URL, activateLinks: Bool, attributes: [NSAttributedString.Key : Any]) {
        let range = mutableString.range(of: text)
        assert(range.location != NSNotFound, "This should never happen but if it does, the `text` may include some special characters.")
        if range.location != NSNotFound {
            if activateLinks {
                addAttribute(.link, value: url.absoluteString, range: range)
            }
            addAttributes(attributes, range: range)
            addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: range)
        }
    }
}
