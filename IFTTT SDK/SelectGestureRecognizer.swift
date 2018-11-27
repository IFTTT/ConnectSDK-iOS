//
//  SelectGestureRecognizer.swift
//  IFTTT SDK
//
//  Created by Jon Chmura on 11/26/18.
//  Copyright © 2018 IFTTT. All rights reserved.
//

import UIKit

@available(iOS 10.0, *)
class SelectGestureRecognizer: UIGestureRecognizer {
    
    var cancelsOnForceTouch: Bool = false
    
    private(set) var isHighlighted: Bool = false {
        didSet {
            performHighlight?(view, isHighlighted)
        }
    }
    
    /// Transition the view to its highlighted state
    /// Default implementation reduces the view's alpha to 0.8
    /// Set to nil to disable highlighting
    var performHighlight: ((UIView?, Bool) -> Void)? = { (view: UIView?, isHighlighted: Bool) -> Void in
        view?.alpha = isHighlighted ? 0.8 : 1
    }
    
    var touchesBeganDelay: CFTimeInterval = 0.1
    var touchesCancelledDistance: CGFloat = 10
    
    private var gestureOrigin: CGPoint?
    
    private var currentEvent: UIEvent?
    
    override var state: UIGestureRecognizer.State {
        didSet {
            guard performHighlight != nil else { return }
            
            switch state {
            case .began:
                isHighlighted = true
            case .ended:
                // Touches have ended but we're not already in the touch state which means this was a tap so show the tap animation
                if isHighlighted == false {
                    isHighlighted = true
                    UIView.animate(withDuration: 0.2, delay: 0.2, options: [], animations: {
                        self.isHighlighted = false
                    }, completion: nil)
                } else {
                    isHighlighted = false
                }
            case .cancelled:
                isHighlighted = false
            default:
                break
            }
        }
    }
    
    override func reset() {
        super.reset()
        
        gestureOrigin = nil
        currentEvent = nil
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        if touches.contains(where: { $0.force > 1 }) {
            return
        }
        
        currentEvent = event
        
        if let touch = touches.first, let view = view {
            gestureOrigin = touch.location(in: view)
        } else {
            gestureOrigin = nil
        }
        
        if delaysTouchesBegan {
            DispatchQueue.main.asyncAfter(deadline: .now() + touchesBeganDelay) {
                if event == self.currentEvent {
                    self.state = .began
                }
            }
        } else {
            state = .began
        }
    }
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        if touches.contains(where: { $0.force > 1 && cancelsOnForceTouch }) {
            state = .cancelled
        }
        
        if let origin = gestureOrigin, let touch = touches.first, let view = view {
            let current = touch.location(in: view)
            let distance = sqrt(pow(current.x - origin.x, 2) + pow(current.y - origin.y, 2))
            
            if distance > touchesCancelledDistance {
                state = .cancelled
            }
        }
    }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        state = .ended
    }
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
        state = .cancelled
    }
}
