//
//  ConnectButton.swift
//  IFTTT SDK
//
//  Created by Jon Chmura on 8/31/18.
//  Copyright © 2018 IFTTT. All rights reserved.
//

import UIKit
import UIKit.UIGestureRecognizerSubclass

//@IBDesignable
public class ConnectButton: UIView {
    
    enum State {
        case
        initialization,
        toggle(for: Applet.Service, message: String, isOn: Bool),
        email,
        step(for: Applet.Service?, message: String),
        stepComplete(for: Applet.Service?)
        
        struct Transition {
            fileprivate let animator: UIViewPropertyAnimator
            
            func preform() {
                animator.startAnimation()
            }
            func preformWithoutAnimation() {
                animator.startAnimation()
                animator.stopAnimation(false)
                animator.finishAnimation(at: .end)
            }
            func set(progress: CGFloat) {
                animator.pauseAnimation()
                animator.fractionComplete = progress
            }
            func resume(with timing: UITimingCurveProvider, durationAdjustment: TimeInterval?) {
                animator.pauseAnimation()
                var durationFactor: CGFloat = 1
                if let newDuration = durationAdjustment {
                    durationFactor = CGFloat(newDuration / animator.duration)
                }
                animator.continueAnimation(withTimingParameters: timing, durationFactor: durationFactor)
            }
        }
    }
    
    var nextToggleState: (() -> State)?
    
    private(set) var currentState: State = .initialization
    
    func progressTransition(timeout: TimeInterval) -> State.Transition {
        return State.Transition(animator: progressAnimator(duration: timeout))
    }
    
    func transition(to state: State) -> State.Transition {
        let transition = State.Transition(animator: animator(forTransitionTo: state, from: currentState))
        transition.animator.addCompletion { (position) in
            if position == .end {
                self.currentState = state
            }
        }
        return transition
    }
    
    init() {
        super.init(frame: .zero)
        createLayout()
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        self.init()
    }
    
    
    // MARK: - Toggle Interaction
    
    fileprivate lazy var panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
    
    private var currentToggleTransition: State.Transition?
    
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        
    }
    
    
    // MARK: - UI
    
    fileprivate struct Layout {
        static let height: CGFloat = 64
        static let knobInset: CGFloat = 8
        static var knobDiameter: CGFloat {
            return height - 2 * knobInset
        }
        static let checkmarkDiameter: CGFloat = 24
    }
    
   fileprivate  let backgroundView = PillView()
    
    fileprivate let label: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.textColor = .white
        label.font = .ifttt(.callout, isDynamic: false)
        label.adjustsFontSizeToFitWidth = true
        return label
    }()
    
    fileprivate let knob = Knob()
    
    fileprivate let emailConfirmButton = PillButton(image: UIImage(), // FIXME: Asset
                                                    tintColor: .white,
                                                    backgroundColor: .iftttBlack)
    
    fileprivate let emailEntryField: UITextField = {
        let field = UITextField(frame: .zero)
        field.placeholder = .localized("connect_button.email.placeholder")
        return field
    }()
    
    fileprivate let progressBar = UIView()
    
    fileprivate let checkmark = CheckmarkView()
    
    fileprivate class Knob: PillView {
        let iconView = UIImageView()
        
        override init() {
            super.init()
            
            backgroundColor = .iftttBlue
            
            layoutMargins = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
            addSubview(iconView)
            iconView.constrain.edges(to: layoutMarginsGuide)
        }
    }
    
    fileprivate class CheckmarkView: UIView {
        let circle = UIView()
        
        init() {
            super.init(frame: .zero)
            
            addSubview(circle)
            circle.layer.borderWidth = 2
            circle.layer.borderColor = UIColor(white: 1, alpha: 0.5).cgColor
            
            circle.constrain.center(in: self)
            circle.constrain.square(length: Layout.checkmarkDiameter)
        }
        @available(*, unavailable)
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
    
    private var labelEdgeConstraint: NSLayoutConstraint!
    
    private var switchOffConstraint: NSLayoutConstraint!
    private var switchOnConstraint: NSLayoutConstraint!
    
    private func createLayout() {
        addSubview(backgroundView)
        backgroundView.addSubview(progressBar)
        backgroundView.addSubview(label)
        backgroundView.addSubview(emailEntryField)
        backgroundView.addSubview(checkmark)
        backgroundView.addSubview(knob)
        backgroundView.addSubview(emailConfirmButton)
        
        backgroundView.clipsToBounds = true
        backgroundView.layoutMargins = UIEdgeInsets(top: Layout.knobInset,
                                                    left: 0.5 * Layout.height,
                                                    bottom: Layout.knobInset,
                                                    right: 0.5 * Layout.height)
        
        backgroundView.constrain.edges(to: self)
        backgroundView.heightAnchor.constraint(equalToConstant: Layout.height).isActive = true
        
        progressBar.constrain.edges(to: self)
        
        // Center the label and don't allow it to overlap with the knob
        label.constrain.center(in: self)
        labelEdgeConstraint = label.leftAnchor.constraint(equalTo: backgroundView.layoutMarginsGuide.leftAnchor)
        labelEdgeConstraint.isActive = true
        
        knob.constrain.square(length: Layout.knobDiameter)
        knob.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        
        // When activated, the switch is in the off position (takes priority over the on constraint)
        switchOffConstraint = knob.centerXAnchor.constraint(equalTo: backgroundView.layoutMarginsGuide.leftAnchor)
        switchOffConstraint.isActive = true
        
        switchOnConstraint = knob.centerXAnchor.constraint(equalTo: backgroundView.layoutMarginsGuide.rightAnchor)
        switchOnConstraint.priority = .defaultHigh
        switchOnConstraint.isActive = true
        
        emailEntryField.constrain.edges(to: backgroundView.layoutMarginsGuide)
        
        // In animations involving the email confirm button, it always tracks along with the switch knob
        emailConfirmButton.constrain.center(in: knob)
        emailConfirmButton.constrain.square(length: Layout.height)
        
        checkmark.constrain.center(in: self)
        
        [label, knob, emailEntryField, emailConfirmButton, checkmark, progressBar].forEach {
            $0.alpha = 0
        }
        
        backgroundView.addGestureRecognizer(panGesture)
        panGesture.isEnabled = false
    }
}


// MARK: - Animation

private extension ConnectButton.State {
    var backgroundColor: UIColor {
        switch self {
        case .initialization, .toggle:
            return .iftttBlack
        case .email:
            return .iftttLightGrey
        case .step(let service, _):
            return service?.brandColor ?? .iftttBlack
        case .stepComplete(let service):
            return service?.brandColor ?? .iftttBlack
        }
    }
}

private extension ConnectButton {
    var animationDuration: TimeInterval { return 2 }
    
    func progressAnimator(duration: TimeInterval) -> UIViewPropertyAnimator {
        progressBar.transform = CGAffineTransform(translationX: -bounds.width, y: 0)
        let animator = UIViewPropertyAnimator(duration: duration, curve: .linear) {
            self.progressBar.transform = .identity
        }
        return animator
    }
    
    func animator(forTransitionTo state: State, from previousState: State) -> UIViewPropertyAnimator {
        let animator = UIViewPropertyAnimator(duration: animationDuration,
                                              timingParameters: UISpringTimingParameters(dampingRatio: 1,
                                                                                         initialVelocity: .zero))
        switch (previousState, state) {
        case (.initialization, .toggle(let service, let message, let isOn)): // Setup switch
            switchOffConstraint.isActive = !isOn
            animator.addAnimations {
                self.backgroundView.layoutIfNeeded()
                self.backgroundView.backgroundColor = state.backgroundColor
                self.knob.backgroundColor = service.brandColor
                self.knob.curvature = 1
                self.knob.alpha = 1
                self.label.alpha = 1
            }
            knob.iconView.set(imageURL: service.colorIconURL)
            label.text = message // FIXME: Animate text
            
        case (.toggle, .toggle(_, let message, let isOn)): // Toggle On <==> Off
            switchOffConstraint.isActive = !isOn
            animator.addAnimations {
                self.backgroundView.layoutIfNeeded()
            }
            label.text = message // FIXME: Animate text
            
        case (.toggle(_, _, let isOn), .email) where isOn == false: // Connect to enter email
            let scaleFactor = Layout.height / Layout.knobDiameter
            
            emailConfirmButton.transform = CGAffineTransform(scaleX: 1 / scaleFactor, y: 1 / scaleFactor)
            emailConfirmButton.curvature = 1
            switchOffConstraint.isActive = false
            
            animator.addAnimations {
                self.backgroundView.layoutIfNeeded()
                self.backgroundView.backgroundColor = state.backgroundColor
                
                self.label.alpha = 0 // FIXME: Should mask from left to right along with switch
                
                self.knob.transform = CGAffineTransform(scaleX: scaleFactor, y: scaleFactor)
                self.knob.curvature = 0
                self.knob.alpha = 0
                
                self.emailConfirmButton.transform = .identity
                self.emailConfirmButton.curvature = 0
                self.emailConfirmButton.alpha = 1
                
                self.emailEntryField.alpha = 1
            }
            animator.addCompletion { (_) in
                // Keep the knob is a "clean" state since we don't animate backwards from this step
                self.knob.transform = .identity
                self.knob.curvature = 1
            }
            
        case (.email, .step(_, let message)): // Email to step progress
            animator.addAnimations {
                self.emailEntryField.alpha = 0
                self.emailConfirmButton.transform = CGAffineTransform(translationX: self.emailConfirmButton.bounds.width, y: 0)
                
                self.backgroundView.backgroundColor = state.backgroundColor.withAlphaComponent(0.5)
                self.progressBar.backgroundColor = state.backgroundColor
                
                self.label.alpha = 1
                self.progressBar.alpha = 1
            }
            animator.addCompletion { (_) in
                self.emailConfirmButton.alpha = 0
                self.emailConfirmButton.transform = .identity
            }
            label.text = message // FIXME: Animate text
            
        case (.step, .step(_, let message)): // Changing the message during a step
            label.text = message // FIXME: Animate text
            
        case (.step, .stepComplete(let service)): // Completing a step
            break
            
        case (.stepComplete, .step(let service, _)): // Starting next step
            break
            
        case (.stepComplete, .toggle(let service, _, let isOn)): // Transition back to toggle after completely a flow
            break
            
        default:
            fatalError("Connect button state transition is invalid")
        }
        return animator
    }
}
