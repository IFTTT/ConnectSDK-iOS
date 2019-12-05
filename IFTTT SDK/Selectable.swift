//
//  Selectable.swift
//  IFTTT SDK
//
//  Copyright © 2019 IFTTT. All rights reserved.
//

import UIKit

class Selectable: NSObject, UIGestureRecognizerDelegate {
    var isEnabled: Bool {
        get { return gesture.isEnabled }
        set { gesture.isEnabled = newValue }
    }
    
    /// Customize the behavior when the Selectable view is highlighted
    var performHighlight: SelectGestureRecognizer.HighlightHandler? {
        get {
            return gesture.performHighlight
        }
        set {
            gesture.performHighlight = newValue
        }
    }
    
    private let gesture = SelectGestureRecognizer()
    private var onSelect: VoidClosure
    
    init(_ view: UIView, onSelect: @escaping VoidClosure) {
        self.onSelect = onSelect
        
        super.init()
        
        gesture.addTarget(self, action: #selector(handleSelect(_:)))
        gesture.delaysTouchesBegan = true
        gesture.delegate = self
        
        view.addGestureRecognizer(gesture)
        view.isUserInteractionEnabled = true
    }
    
    @objc private func handleSelect(_ gesture: UIGestureRecognizer) {
        if gesture.state == .ended {
            onSelect()
        }
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
