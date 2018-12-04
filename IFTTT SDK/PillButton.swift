//
//  PillButton.swift
//  IFTTT SDK
//
//  Created by Jon Chmura on 11/26/18.
//  Copyright © 2018 IFTTT. All rights reserved.
//

import UIKit

@available(iOS 10.0, *)
class PillButton: PillView {
    
    let label = UILabel()
    
    let imageView = UIImageView()
    
    func onSelect(_ body: @escaping (() -> Void)) {
        assert(selectable == nil, "PillButton may have a single select handler")
        selectable = Selectable(self, onSelect: body)
    }
    
    private var selectable: Selectable?
    
    override var intrinsicContentSize: CGSize {
        if imageView.image != nil {
            var size = imageView.intrinsicContentSize
            size.height += 20
            size.width += 20
            return size
        } else {
            return super.intrinsicContentSize
        }
    }
    
    init(_ image: UIImage, _ configure: ((PillButton) -> Void)? = nil) {
        super.init()
        
        addSubview(imageView)
        imageView.constrain.center(in: self)
        
        imageView.image = image
        
        configure?(self)
    }
    
    init(_ text: String, _ configure: ((PillButton) -> Void)? = nil) {
        super.init()
        
        label.text = text
        label.textAlignment = .center
        
        layoutMargins = UIEdgeInsets(top: 12, left: 32, bottom: 12, right: 32)
        addSubview(label)
        label.constrain.edges(to: layoutMarginsGuide)
        
        configure?(self)
    }
}