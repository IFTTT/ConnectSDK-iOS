//
//  EmailValidator.swift
//  IFTTT SDK
//
//  Copyright © 2019 IFTTT. All rights reserved.
//

import Foundation

/// Determines the validity of an email address.
struct EmailValidator {
    
    /// Validates the parameter string to make sure it's a valid email address.
    ///
    /// - Parameters:
    ///     - text: The email address to validate.
    /// - Returns: A boolean value that determines whether or not the parameter text is a valid email address or not.
    func validate(with text: String) -> Bool {
        // An empty string is not a valid email
        if text.isEmpty { return false }
        
        // Use NSDataDetector to determine whether or not the text is valid
        guard let dataDetector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) else {
            return false
        }
        
        // Remove any spaces in the text
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let range = NSMakeRange(0, NSString(string: trimmedText).length)
        let allMatches = dataDetector.matches(in: trimmedText,
                                              options: [],
                                              range: range)
        
        if allMatches.count == 1, allMatches.first?.url?.absoluteString.contains("mailto:") == true {
            return true
        }
        return false
    }
}
