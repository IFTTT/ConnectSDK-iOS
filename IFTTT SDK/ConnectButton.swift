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
                animator.finishAnimation(at: .end)
            }
            func set(progress: CGFloat) {
                animator.pauseAnimation()
                animator.fractionComplete = progress
            }
            func complete(with timing: UITimingCurveProvider) {
                animator.continueAnimation(withTimingParameters: timing, durationFactor: 1)
            }
        }
    }
    
    private(set) var currentState: State = .initialization
    
//    func transition(to state: State) -> State.Transition {
//        
//    }
    
    init() {
        super.init(frame: .zero)
        createLayout()
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        self.init()
    }
    
    
    // MARK: - Toggle Interaction
    
    fileprivate lazy var panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
    
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        
    }
    
    
    // MARK: - UI
    
    struct Layout {
        static let height: CGFloat = 64
        static let knobInset: CGFloat = 8
        static var knobDiameter: CGFloat {
            return height - 2 * knobInset
        }
        static let checkmarkDiameter: CGFloat = 24
    }
    
    let backgroundView = PillView()
    
    let label: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.textColor = .white
        label.font = .ifttt(.callout, isDynamic: false)
        label.adjustsFontSizeToFitWidth = true
        return label
    }()
    
    let switchKnob = Knob()
    
    let emailConfirmButton = PillButton(image: UIImage(), backgroundColor: .iftttBlack)
    
    let emailEntryField: UITextField = {
        let field = UITextField(frame: .zero)
        field.placeholder = .localized("connect_button.email.placeholder")
        return field
    }()
    
    let progressBar = UIView()
    
    let checkmark = CheckmarkView()
    
    class Knob: PillView {
        let iconView = UIImageView()
        
        override init() {
            super.init()
            
            backgroundColor = .iftttBlue
            
            layoutMargins = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
            addSubview(iconView)
            iconView.constrain.edges(to: layoutMarginsGuide)
        }
    }
    
    class CheckmarkView: UIView {
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
        backgroundView.addSubview(switchKnob)
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
        
        switchKnob.constrain.square(length: Layout.knobDiameter)
        switchKnob.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        
        // When activated, the switch is in the off position (takes priority over the on constraint)
        switchOffConstraint = switchKnob.centerXAnchor.constraint(equalTo: backgroundView.layoutMarginsGuide.leftAnchor)
        switchOffConstraint.isActive = true
        
        switchOnConstraint = switchKnob.centerXAnchor.constraint(equalTo: backgroundView.layoutMarginsGuide.rightAnchor)
        switchOnConstraint.priority = .defaultHigh
        switchOnConstraint.isActive = true
        
        emailEntryField.constrain.edges(to: backgroundView.layoutMarginsGuide)
        
        // In animations involving the email confirm button, it always tracks along with the switch knob
        emailConfirmButton.constrain.center(in: switchKnob)
        emailConfirmButton.constrain.square(length: Layout.height)
        
        checkmark.constrain.center(in: self)
        
        [label, switchKnob, emailEntryField, emailConfirmButton, checkmark, progressBar].forEach {
            $0.alpha = 0
        }
        
        backgroundView.addGestureRecognizer(panGesture)
        panGesture.isEnabled = false
    }
}


// MARK: - Animation

extension ConnectButton {
    func animator(forTransitionTo state: State, from previousState: State) -> UIViewPropertyAnimator {
        let animator = UIViewPropertyAnimator(duration: 0.25,
                                              timingParameters: UISpringTimingParameters(dampingRatio: 1,
                                                                                         initialVelocity: .zero))
        switch (previousState, state) {
        case (.initialization, .toggle(let service, let message, let isOn)): // Setup switch
            animator.addAnimations {
                self.switchKnob.backgroundColor = service.brandColor
            }
            
        case (.toggle(_, _, let previouslyOn), .toggle(_, _, let isOn)): // Toggle On <==> Off
            if isOn != previouslyOn {
                switchOffConstraint.isActive = !isOn
                animator.addAnimations {
                    self.backgroundView.layoutIfNeeded()
                }
            }
            
        case (.toggle(_, _, let isOn), .email) where isOn == false: // Connect to enter email
            emailConfirmButton.curvature = 1
            switchOffConstraint.isActive = false
            animator.addAnimations {
                self.backgroundView.layoutIfNeeded()
                self.backgroundView.backgroundColor = .iftttLightGrey
                
                self.label.alpha = 0 // FIXME: Should mask from left to right along with switch
                
                self.emailConfirmButton.curvature = 0
                self.emailConfirmButton.alpha = 1
                
                self.emailEntryField.alpha = 1
            }
            
        case (.email, .step(let service, _)): // Email to step progress
            break
            
        case (.step, .step(let service, _)): // Progressing through a step
            break
            
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
