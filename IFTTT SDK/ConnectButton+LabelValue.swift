//
//  ConnectButton+LabelValue.swift
//  IFTTT SDK
//
//  Created by Michael Amundsen on 5/23/19.
//  Copyright © 2019 IFTTT. All rights reserved.
//

import Foundation

@available(iOS 10.0, *)
extension ConnectButton {
    
    enum LabelValue: Equatable {
        case
        none,
        text(String),
        attributed(NSAttributedString)
        
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
