//
//  UIView+Helpers.swift
//  Grocery Express
//
//  Copyright © 2020 IFTTT. All rights reserved.
//

import Foundation
import UIKit

extension UIView {
    func fillConstraint(view: UIView, attribute: NSLayoutConstraint.Attribute, constant: CGFloat = 0.0) -> NSLayoutConstraint {
        return .init(item: view,
                     attribute: attribute,
                     relatedBy: .equal,
                     toItem: self,
                     attribute: attribute,
                     multiplier: 1.0,
                     constant: constant)
    }
    
    func fillConstraints(view: UIView, constant: CGFloat = 0.0) -> [NSLayoutConstraint] {
        let attributes: [NSLayoutConstraint.Attribute] = [.leading, .top, .bottom, .trailing]
        return attributes.map {
            .init(item: view,
                  attribute: $0,
                  relatedBy: .equal,
                  toItem: self,
                  attribute: $0,
                  multiplier: 1.0,
                  constant: constant)
        }
    }
    
    private func sizeConstraint(attribute: NSLayoutConstraint.Attribute, constant: CGFloat) -> NSLayoutConstraint {
        return NSLayoutConstraint(item: self,
                                  attribute: attribute,
                                  relatedBy: .equal,
                                  toItem: nil,
                                  attribute: .notAnAttribute,
                                  multiplier: 1,
                                  constant: constant)
    }
    
    func sizeConstraints(size: CGSize) -> [NSLayoutConstraint] {
        return [
            sizeConstraint(attribute: .height, constant: size.height),
            sizeConstraint(attribute: .width, constant: size.width)
        ]
    }
}

extension UIStackView {
    /// Removes all arranged subviews of a UIStackView.
    func removeAllArrangedSubviews() {
        arrangedSubviews.forEach {
            removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        
        layoutIfNeeded()
    }
}
