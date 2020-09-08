//
//  PillButton.swift
//  IFTTT SDK
//
//  Copyright © 2019 IFTTT. All rights reserved.
//

import UIKit

class PillButton: PillView {
    
    let label = UILabel()
    
    let imageView = UIImageView()
    
    func onSelect(_ body: @escaping VoidClosure) {
        assert(selectable == nil, "PillButton may have a single select handler")
        selectable = Selectable(self, onSelect: body)
        selectable?.performHighlight = { [weak self] _, isHighlighted in
            self?.label.alpha = isHighlighted ? 0.8 : 1
            self?.imageView.alpha = isHighlighted ? 0.8 : 1
            self?.isHighlighted = isHighlighted
        }
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
    
    init(_ image: UIImage?, _ configure: ((PillButton) -> Void)? = nil) {
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
