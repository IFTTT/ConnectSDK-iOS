//
//  ConnectButton+LabelAnimator.swift
//  IFTTT SDK
//
//  Created by Michael Amundsen on 5/23/19.
//  Copyright © 2019 IFTTT. All rights reserved.
//

import Foundation

@available(iOS 10.0, *)
extension ConnectButton {
    
    class LabelAnimator {
        
        typealias View = (label: UILabel, view: UIStackView)
        
        let primary: View
        let transition: View
        
        private var currrentValue: LabelValue = .none
        
        init(_ configuration: @escaping (UILabel) -> Void) {
            primary = LabelAnimator.views(configuration)
            transition = LabelAnimator.views(configuration)
        }
        
        static func views(_ configuration: @escaping (UILabel) -> Void) -> View {
            let label = UILabel("", configuration)
            return (label, UIStackView([label]) {
                $0.isLayoutMarginsRelativeArrangement = true
                $0.layoutMargins = .zero
            })
        }
        
        enum Effect {
            case
            crossfade,
            slideInFromRight,
            rotateDown
        }
        
        struct Insets {
            let left: CGFloat
            let right: CGFloat
            
            static let standardInsetValue = 0.5 * Layout.height
            static let zero = Insets(left: 0, right: 0)
            static let standard = Insets(left: standardInsetValue, right: standardInsetValue)
            static let avoidLeftKnob = Insets(left: Layout.knobDiameter + 20, right: standardInsetValue)
            static let avoidRightKnob = Insets(left: standardInsetValue, right: Layout.knobDiameter + 20)
            
            fileprivate func apply(_ view: UIStackView) {
                view.layoutMargins.left = left
                view.layoutMargins.right = right
            }
        }
        
        func configure(_ value: LabelValue, insets: Insets? = nil) {
            value.update(label: primary.label)
            insets?.apply(primary.view)
            currrentValue = value
        }
        
        func transition(with effect: Effect,
                        updatedValue: LabelValue,
                        insets: Insets? = nil,
                        addingTo animator: UIViewPropertyAnimator) {
            guard updatedValue != currrentValue else {
                animator.addAnimations { }
                return
            }
            
            // Update the transition to view
            transition.view.isHidden = false
            insets?.apply(transition.view)
            updatedValue.update(label: transition.label)
            
            // Set final state at the end of the animation
            animator.addCompletion { position in
                self.transition.view.isHidden = true
                self.transition.label.alpha = 0
                self.transition.label.transform = .identity
                
                self.primary.label.alpha = 1
                self.primary.label.transform = .identity
                
                if position == .end {
                    insets?.apply(self.primary.view)
                    updatedValue.update(label: self.primary.label)
                    self.currrentValue = updatedValue
                }
            }
            
            switch effect {
            case .crossfade:
                transition.label.alpha = 0
                animator.addAnimations {
                    self.primary.label.alpha = 0
                }
                
                // Fade in the new label as the second part of the animation
                animator.addAnimations({
                    self.transition.label.alpha = 1
                }, delayFactor: 0.5)
                
            case .slideInFromRight:
                transition.label.alpha = 0
                transition.label.transform = CGAffineTransform(translationX: 20, y: 0)
                animator.addAnimations {
                    // In this animation we don't expect there to be any text in the previous state
                    // But just for prosterity, let's fade out the old value
                    self.primary.label.alpha = 0
                    
                    self.transition.label.transform = .identity
                    self.transition.label.alpha = 1
                }
                
            case .rotateDown:
                let translate: CGFloat = 12
                
                // Starting position for the new text
                // It will rotate down into place
                transition.label.alpha = 0
                transition.label.transform = CGAffineTransform(translationX: 0, y: -translate)
                
                animator.addAnimations {
                    // Fade out the current text and rotate it down
                    self.primary.label.alpha = 0
                    self.primary.label.transform = CGAffineTransform(translationX: 0, y: translate)
                }
                animator.addAnimations({
                    // Fade in the new text and rotate down from the top
                    self.transition.label.alpha = 1
                    self.transition.label.transform = .identity
                }, delayFactor: 0.5)
            }
        }
    }
}
