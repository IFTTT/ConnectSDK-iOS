//
//  UIKit+ConvenienceInit.swift
//  IFTTT SDK
//
//  Copyright © 2019 IFTTT. All rights reserved.
//

import UIKit

@available(iOS 10.0, *)
extension UILabel {
    convenience init(_ text: String? = nil, _ configure: ((UILabel) -> Void)? = nil) {
        self.init()
        self.text = text
        self.adjustsFontForContentSizeCategory = true
        configure?(self)
    }
    convenience init(_ attributedText: NSAttributedString?, _ configure: ((UILabel) -> Void)? = nil) {
        self.init()
        self.attributedText = attributedText
        self.adjustsFontForContentSizeCategory = true
        configure?(self)
    }
}

@available(iOS 10.0, *)
extension UIStackView {
    convenience init(_ views: [UIView] = [], _ configure: ((UIStackView) -> Void)) {
        self.init(arrangedSubviews: views)
        configure(self)
    }
}
