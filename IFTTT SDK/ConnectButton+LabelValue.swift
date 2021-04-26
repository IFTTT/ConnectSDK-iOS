//
//  ConnectButton+LabelValue.swift
//  IFTTT SDK
//
//  Copyright © 2019 IFTTT. All rights reserved.
//

import UIKit

extension ConnectButton {
    
    /// Wraps various ways a `UILabel`'s text can be set.
    enum LabelValue: Equatable {
        
        /// The label has no text.
        case none
        
        /// The text of the label.
        case text(String)
        
        /// The attributed text of the label.
        case attributed(NSAttributedString)
        
        /// Updates the label with the value of the enum.
        ///
        /// - Parameter label: The label to update the text on.
        func update(label: UILabel) {
            switch self {
            case .none:
                label.text = nil
                label.attributedText = nil
            case .text(let text):
                label.text = text
            case .attributed(let text):
                label.attributedText = text
            }
        }
        
        /// Whether there is text provided.
        var isEmpty: Bool {
            if case .none = self {
                return true
            }
            return false
        }
        
        static func ==(lhs: LabelValue, rhs: LabelValue) -> Bool {
            switch (lhs, rhs) {
            case (.none, .none):
                return true
            case (.text(let lhs), .text(let rhs)):
                return lhs == rhs
            case (.attributed(let lhs), .attributed(let rhs)):
                return lhs == rhs
            default:
                return false
            }
        }
    }
    
}
