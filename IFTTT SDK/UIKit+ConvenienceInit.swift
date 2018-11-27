//
//  UIKit+ConvenienceInit.swift
//  IFTTT SDK
//
//  Created by Jon Chmura on 11/26/18.
//  Copyright © 2018 IFTTT. All rights reserved.
//

import UIKit

extension UILabel {
    convenience init(_ text: String, _ configure: ((UILabel) -> Void)?) {
        self.init()
        self.text = text
        configure?(self)
    }
    convenience init(_ attributedText: NSAttributedString, _ configure: ((UILabel) -> Void)?) {
        self.init()
        self.attributedText = attributedText
        configure?(self)
    }
}

@available(iOS 10.0, *)
extension UIStackView {
    convenience init(_ views: [UIView], _ configure: ((UIStackView) -> Void)?) {
        self.init(arrangedSubviews: views)
        configure?(self)
    }
}
