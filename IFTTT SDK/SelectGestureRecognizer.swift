//
//  SelectGestureRecognizer.swift
//  IFTTT SDK
//
//  Copyright © 2019 IFTTT. All rights reserved.
//

import UIKit

@available(iOS 10.0, *)
class SelectGestureRecognizer: UIGestureRecognizer {
    
    typealias HighlightHandler = ((UIView?, Bool) -> Void)
    
    var cancelsOnForceTouch: Bool = false
    
    private(set) var isHighlighted: Bool = false {
        didSet {
            performHighlight?(view, isHighlighted)
        }
    }
    
    /// Transition the view to its highlighted state
    /// Default implementation reduces the view's alpha to 0.8
    /// Set to nil to disable highlighting
    var performHighlight: HighlightHandler? = { (view: UIView?, isHighlighted: Bool) -> Void in
        UIView.animate(withDuration: 0.1) {
            view?.alpha = isHighlighted ? 0.8 : 1
        }
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
                    // Set the alpha immediately to selected and then animate to the unselected state.
                    UIViewPropertyAnimator.runningPropertyAnimator(withDuration: 0.15, delay: 0, options: [], animations: {
                        self.isHighlighted = true
                    }) { (_) in
                        UIViewPropertyAnimator(duration: 0.15, curve: .easeOut, animations: {
                            self.isHighlighted = false
                        }).startAnimation()
                    }
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
