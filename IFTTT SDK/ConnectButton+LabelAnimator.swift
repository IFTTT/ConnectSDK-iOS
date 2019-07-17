//
//  ConnectButton+LabelAnimator.swift
//  IFTTT SDK
//
//  Copyright © 2019 IFTTT. All rights reserved.
//

import Foundation

@available(iOS 10.0, *)
extension ConnectButton {
    
    /// A clas that wraps the ability to animate a `UILabel` to and from a value.
    final class LabelAnimator {
        
        /// Represents the the views the `LabelAnimator` is controlling.
        typealias View = (label: UILabel, view: UIStackView)
        
        /// The primary `View` that is used by the label animator.
        let primary: View
        
        /// The transition `View` that is used by the label animator.
        let transition: View
        
        private var currrentValue: LabelValue = .none
        
        /// Creates a `LabelAnimator`.
        ///
        /// - Parameter configuration: A configuration closure for configuring the `UILabel`.
        init(_ configuration: @escaping (UILabel) -> Void) {
            primary = LabelAnimator.views(configuration)
            transition = LabelAnimator.views(configuration)
        }
        
        private static func views(_ configuration: @escaping (UILabel) -> Void) -> View {
            let label = UILabel("", configuration)
            return (label, UIStackView([label]) {
                $0.isLayoutMarginsRelativeArrangement = true
                $0.layoutMargins = .zero
            })
        }
        
        /// Represents the insets for the labels of the label animator.
        struct Insets {
            
            /// The value the label should be inset from the left.
            let left: CGFloat
            
            /// The value the label should be inset from the right.
            let right: CGFloat
            
            private static let standardInsetValue = 0.5 * Layout.height
            
            /// An inset of zero.
            static let zero = Insets(left: 0, right: 0)
            
            /// The default amount of inset.
            static let standard = Insets(left: standardInsetValue, right: standardInsetValue)
            
            /// An inset to avoid the connect button knob on the left.
            static let avoidLeftKnob = Insets(left: Layout.knobDiameter + 20, right: standardInsetValue)
            
            /// An inset to avoid the connect button knob on the right.
            static let avoidRightKnob = Insets(left: standardInsetValue, right: Layout.knobDiameter + 20)
            
            fileprivate func apply(_ view: UIStackView) {
                view.layoutMargins.left = left
                view.layoutMargins.right = right
            }
        }
        
        /// Configures the label with the value and insets provided without animating.
        ///
        /// - Parameters:
        ///   - value: The `LabelValue` to update the primary label to.
        ///   - insets: An optional amount to inset the label. Defaults to nil.
        func configure(_ value: LabelValue, insets: Insets? = nil) {
            value.update(label: primary.label)
            insets?.apply(primary.view)
            currrentValue = value
        }
        
        /// Animates configuring the label with the value and insets provided.
        ///
        /// - Parameters:
        ///   - updatedValue: The `LabelValue` to update the primary label to.
        ///   - insets: An optional amount to inset the label. Defaults to nil.
        ///   - animator: The `UIViewPropertyAnimator` to add the animations to.
        func transition(updatedValue: LabelValue,
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
            
            transition.label.alpha = 0
            animator.addAnimations {
                self.primary.label.alpha = 0
            }
            
            // Fade in the new label as the second part of the animation
            animator.addAnimations({
                self.transition.label.alpha = 1
            }, delayFactor: 0.5)
            
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
        }
    }
}
