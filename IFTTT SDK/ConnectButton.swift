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
        step(for: Applet.Service?, message: String, isSelectable: Bool),
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
            func pause() {
                animator.pauseAnimation()
            }
            func set(progress: CGFloat) {
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
    
    var onEmailConfirmed: ((String) -> Void)?
    
    var onStepSelected: (() -> Void)?
    
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
    
    
    // MARK: - UI
    
    fileprivate struct Layout {
        static let height: CGFloat = 64
        static let knobInset: CGFloat = 8
        static var knobDiameter: CGFloat {
            return height - 2 * knobInset
        }
        static let checkmarkDiameter: CGFloat = 42
        static let checkmarkLength: CGFloat = 14
        static let serviceIconDiameter: CGFloat = 24
    }
    
    fileprivate let backgroundView = PillView()
    
    fileprivate let serviceIconView = UIImageView()
    
    // MARK: Email view
    
    fileprivate let emailConfirmButton = PillButton(image: UIImage(), // FIXME: Asset
                                                    tintColor: .white,
                                                    backgroundColor: .iftttBlack)
    
    fileprivate let emailEntryField: UITextField = {
        let field = UITextField(frame: .zero)
        field.placeholder = .localized("connect_button.email.placeholder")
        return field
    }()
    
    // MARK: Label view
    
    fileprivate let label = Label()
    
    class Label: UIView {
        enum Insets {
            case
            standard,
            avoidSwitchKnob
            
            var value: UIEdgeInsets {
                let inset: CGFloat = {
                    switch self {
                    case .standard: return 0.5 * Layout.height
                    case .avoidSwitchKnob: return 0.5 * Layout.height + 0.5 * Layout.knobDiameter + 10
                    }
                }()
                return UIEdgeInsets(top: 0, left: inset, bottom: 0, right: inset)
            }
        }
        
        let view: UILabel = {
            let label = UILabel()
            label.textAlignment = .center
            label.textColor = .white
            label.font = .ifttt(.callout, isDynamic: false)
            label.adjustsFontSizeToFitWidth = true
            return label
        }()
        
        func configure(_ text: String) {
            view.text = text // FIXME: Support animation
        }
        
        var insets: Insets = .standard {
            didSet {
                layoutMargins = insets.value
            }
        }
        
        init() {
            super.init(frame: .zero)
            
            layoutMargins = insets.value
            
            addSubview(view)
            view.constrain.center(in: self)
            view.constrain.edges(to: layoutMarginsGuide, edges: [.left, .right])
        }
        @available(*, unavailable)
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
    
    // MARK: Progress bar
    
    fileprivate let progressBar = ProgressBar()
    
    fileprivate class ProgressBar: UIView {
        var fractionComplete: CGFloat = 0 {
            didSet {
                update()
            }
        }
        
        private let bar = UIView()
        
        func configure(with service: Applet.Service?) {
            bar.backgroundColor = service?.brandColor.contrasting() ?? .iftttBlack
        }
        
        private func update() {
            bar.transform = CGAffineTransform(translationX: (1 - fractionComplete) * -bounds.width, y: 0)
        }
        
        override func layoutSubviews() {
            super.layoutSubviews()
            update()
        }
        
        init() {
            super.init(frame: .zero)
            
            addSubview(bar)
            bar.constrain.edges(to: self)
        }
        @available(*, unavailable)
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
    
    // MARK: Switch control
    
    fileprivate var switchControl = SwitchControl()
    
    fileprivate class SwitchControl: UIView {
        class Knob: PillView {
            let iconView = UIImageView()
            
            override init() {
                super.init()
                
                backgroundColor = .iftttBlue
                
                addSubview(iconView)
                iconView.constrain.center(in: self)
                iconView.constrain.square(length: Layout.serviceIconDiameter)
            }
        }
        
        var isOn: Bool = false {
            didSet {
                centerKnobConstraint.isActive = false
                offConstraint.isActive = !isOn
                track.layoutIfNeeded()
            }
        }
        
        func configure(with service: Applet.Service?) {
            knob.iconView.set(imageURL: service?.colorIconURL)
            knob.backgroundColor = service?.brandColor ?? .iftttBlue
        }
        
        let knob = Knob()
        let track = UIView()
        
        /// Used to prime particular button animations where the know should start in the center
        fileprivate func primeAnimation_centerKnob() {
            UIView.performWithoutAnimation {
                self.offConstraint.isActive = false
                self.centerKnobConstraint.isActive = true
                self.layoutIfNeeded()
            }
        }
        
        private var centerKnobConstraint: NSLayoutConstraint!
        private var offConstraint: NSLayoutConstraint!
        
        init() {
            super.init(frame: .zero)
            
            addSubview(track)
            track.addSubview(knob)
            
            track.constrain.edges(to: self)
            
            knob.constrain.square(length: Layout.knobDiameter)
            knob.centerYAnchor.constraint(equalTo: track.centerYAnchor).isActive = true
            
            centerKnobConstraint = knob.centerXAnchor.constraint(equalTo: track.centerXAnchor)
            centerKnobConstraint.isActive = false
            
            offConstraint = knob.leftAnchor.constraint(equalTo: track.leftAnchor, constant: Layout.knobInset)
            offConstraint.isActive = true
            
            let onConstraint = knob.rightAnchor.constraint(equalTo: track.rightAnchor, constant: -Layout.knobInset)
            onConstraint.priority = .defaultHigh // Lower than off constraint, so we can toggle by enabling / disabling off
            onConstraint.isActive = true
        }
        @available(*, unavailable)
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
    
    // MARK: Checkmark view
    
    fileprivate let checkmark = CheckmarkView()
    
    fileprivate class CheckmarkView: UIView {
        let outline = UIView()
        let indicator = UIView()
        let checkmarkShape = CAShapeLayer()
        
        var indicatorAnimationPath = UIBezierPath()
        
        fileprivate func reset() {
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            checkmarkShape.strokeEnd = 0
            CATransaction.commit()
        }
        
        init() {
            super.init(frame: .zero)
            
            constrain.square(length: Layout.height)
            
            let lineWidth: CGFloat = 3
            
            addSubview(outline)
            outline.layer.borderWidth = lineWidth
            outline.layer.borderColor = UIColor(white: 1, alpha: 0.25).cgColor
            
            outline.constrain.center(in: self)
            outline.constrain.square(length: Layout.checkmarkDiameter)
            
            addSubview(indicator)
            indicator.translatesAutoresizingMaskIntoConstraints = false
            indicator.frame = CGRect(x: 0, y: 0, width: lineWidth, height: lineWidth)
            
            layer.addSublayer(checkmarkShape)
            
            indicator.backgroundColor = .white
            checkmarkShape.fillColor = UIColor.clear.cgColor
            checkmarkShape.strokeColor = UIColor.white.cgColor
            checkmarkShape.lineCap = .round
            checkmarkShape.lineWidth = lineWidth
            
            // Offset by line width (this visually centered the checkmark)
            let center = CGPoint(x: 0.5 * Layout.height - lineWidth, y: 0.5 * Layout.height)
            // The projection of the checkmarks longest arm to the X and Y axes (Since its a 45 / 45 triangle)
            let armProjection = Layout.checkmarkLength / sqrt(2)
            
            let checkmarkStartPoint = CGPoint(x: center.x - 0.5 * armProjection,
                                              y: center.y)
            
            let path = UIBezierPath()
            path.move(to: checkmarkStartPoint)
            path.addLine(to: CGPoint(x: center.x,
                                     y: center.y + 0.5 * armProjection))
            path.addLine(to: CGPoint(x: center.x + armProjection,
                                     y: center.y - 0.5 * armProjection))
            checkmarkShape.path = path.cgPath
            checkmarkShape.strokeEnd = 0
            
            indicatorAnimationPath.move(to: center)
            indicatorAnimationPath.addQuadCurve(to: CGPoint(x: 0,
                                                            y: center.y),
                                                controlPoint: CGPoint(x: 0,
                                                                      y: Layout.height))
            indicatorAnimationPath.addQuadCurve(to: checkmarkStartPoint,
                                                controlPoint: .zero)
        }
        @available(*, unavailable)
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func layoutSubviews() {
            super.layoutSubviews()
            outline.layer.cornerRadius = 0.5 * outline.bounds.height
            indicator.layer.cornerRadius = 0.5 * indicator.bounds.height
            
            checkmarkShape.frame = bounds
        }
    }
    
    // MARK: Layout
    
    private func createLayout() {
        addSubview(backgroundView)
        backgroundView.addSubview(progressBar)
        backgroundView.addSubview(label)
        backgroundView.addSubview(emailEntryField)
        backgroundView.addSubview(checkmark)
        backgroundView.addSubview(switchControl)
        backgroundView.addSubview(emailConfirmButton)
        backgroundView.addSubview(serviceIconView)
        
        backgroundView.clipsToBounds = true
        
        backgroundView.constrain.edges(to: self)
        backgroundView.heightAnchor.constraint(equalToConstant: Layout.height).isActive = true
        
        progressBar.constrain.edges(to: backgroundView)
        
        label.constrain.edges(to: backgroundView)
        
        emailEntryField.constrain.edges(to: backgroundView, inset: Label.Insets.standard.value)
        
        // In animations involving the email confirm button, it always tracks along with the switch knob
        emailConfirmButton.constrain.center(in: switchControl.knob)
        emailConfirmButton.constrain.square(length: Layout.height)
        
        switchControl.constrain.edges(to: self)
        
        checkmark.constrain.center(in: self)
        
        serviceIconView.constrain.square(length: Layout.serviceIconDiameter)
        serviceIconView.centerYAnchor.constraint(equalTo: backgroundView.centerYAnchor).isActive = true
        serviceIconView.centerXAnchor.constraint(equalTo: backgroundView.leftAnchor, constant: 0.5 * Layout.height).isActive = true
        
        [label, switchControl, emailEntryField, emailConfirmButton, checkmark, serviceIconView].forEach {
            $0.alpha = 0
        }
        
        setupInteraction()
    }
    
    
    // MARK: - Interaction
    
    private class ScrollGestureRecognizer: UIPanGestureRecognizer {
        override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
            if (self.state == .began) { return }
            super.touchesBegan(touches, with: event)
            self.state = .began
        }
    }
    
    private lazy var selectGesture = SelectGestureRecognizer(target: self, action: #selector(handleSelect(_:)))
    
    private lazy var panGesture = ScrollGestureRecognizer(target: self, action: #selector(handlePan(_:)))
    
    private var currentToggleTransition: State.Transition?
    
    private func getToggleTransition() -> State.Transition? {
        if currentToggleTransition != nil {
            return currentToggleTransition
        }
        guard case .toggle(let service, let message, let isOn) = currentState else {
            return nil
        }
        let nextState = nextToggleState?() ?? .toggle(for: service, message: message, isOn: !isOn)
        return transition(to: nextState)
    }
    
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let transition = getToggleTransition() else {
            return
        }
        switch gesture.state {
        case .possible:
            break
        case .began:
            break
//            transition.preform()
//            transition.pause()
        case .changed:
            break
//            let location = gesture.location(in: switchControl).x
//            let progress = location / switchControl.bounds.width
//            transition.set(progress: progress)
//            debugPrint("PROGRESS: \(progress)")
        case .ended:
            transition.preform() 
        case .cancelled, .failed:
            break
        }
    }
    
    @objc private func handleSelect(_ gesture: UIGestureRecognizer) {
        if gesture.state == .ended {
            onStepSelected?()
        }
    }
    
    private func setupInteraction() {
        backgroundView.addGestureRecognizer(selectGesture)
        selectGesture.delaysTouchesBegan = true
        selectGesture.delegate = self
        selectGesture.isEnabled = false
        
        switchControl.addGestureRecognizer(panGesture)
        panGesture.delegate = self
        
        emailConfirmButton.onSelect = { [weak self] in
            self?.confirmEmail()
        }
        emailEntryField.delegate = self
    }
    
    fileprivate func confirmEmail() {
        let _ = emailEntryField.resignFirstResponder()
        guard let email = emailEntryField.text, email.isValidEmail else {
            // FIXME: Maybe shake the button to indicate the input is invalid
            return
        }
        onEmailConfirmed?(email)
    }
}

extension ConnectButton: UIGestureRecognizerDelegate {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}


// MARK: Text field delegate (email)

private extension String {
    var isValidEmail: Bool {
        if isEmpty == false, let atIndex = lastIndex(of: "@"), let dotIndex = lastIndex(of: "."), atIndex < dotIndex {
            return true
        }
        return false
    }
}

extension ConnectButton: UITextFieldDelegate {
    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        confirmEmail()
        return true
    }
}


// MARK: - Animation

private extension ConnectButton.CheckmarkView {
    func drawCheckmark(duration: TimeInterval) {
        UIView.performWithoutAnimation {
            self.indicator.alpha = 1
        }
        reset()
        
        let indicatorAnimation = CAKeyframeAnimation(keyPath: "position")
        indicatorAnimation.path = indicatorAnimationPath.cgPath
        indicatorAnimation.duration = 0.6 * duration
        indicatorAnimation.timingFunction = CAMediaTimingFunction(name: .easeIn)
        indicatorAnimation.delegate = self
        indicator.layer.add(indicatorAnimation, forKey: "position along path")
        indicator.layer.position = indicatorAnimationPath.currentPoint
    }
}

extension ConnectButton.CheckmarkView: CAAnimationDelegate {
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        if anim is CAKeyframeAnimation {
            indicator.alpha = 0
            
            checkmarkShape.strokeEnd = 1
            let checkmarkAnimation = CABasicAnimation(keyPath: "strokeEnd")
            checkmarkAnimation.fromValue = 0
            checkmarkAnimation.toValue = 1
            checkmarkAnimation.duration = 0.4 * anim.duration
            checkmarkAnimation.timingFunction = CAMediaTimingFunction(name: .easeOut)
            self.checkmarkShape.add(checkmarkAnimation, forKey: "draw line")
        }
    }
}

private extension ConnectButton {
    var animationDuration: TimeInterval { return 0.5 }
    
    func progressAnimator(duration: TimeInterval) -> UIViewPropertyAnimator {
        progressBar.fractionComplete = 0
        let animator = UIViewPropertyAnimator(duration: duration, curve: .linear) {
            self.progressBar.fractionComplete = 1
        }
        return animator
    }
    
    func animator(forTransitionTo state: State, from previousState: State) -> UIViewPropertyAnimator {
        let animator = UIViewPropertyAnimator(duration: animationDuration,
                                              timingParameters: UISpringTimingParameters(dampingRatio: 1,
                                                                                         initialVelocity: .zero))
        switch (previousState, state) {
        case (.initialization, .toggle(let service, let message, let isOn)): // Setup switch
            animator.addAnimations {
                self.backgroundView.backgroundColor = .iftttBlack
                self.switchControl.configure(with: service)
                self.switchControl.isOn = isOn
                self.switchControl.knob.curvature = 1
                self.switchControl.alpha = 1
                self.label.alpha = 1
                self.label.configure(message)
            }
            
        case (.toggle, .toggle(_, let message, let isOn)): // Toggle On <==> Off
            animator.addAnimations {
                self.switchControl.isOn = isOn
                self.label.configure(message)
            }
            
        case (.toggle(_, _, let isOn), .email) where isOn == false: // Connect to enter email
            let scaleFactor = Layout.height / Layout.knobDiameter
            
            emailConfirmButton.transform = CGAffineTransform(scaleX: 1 / scaleFactor, y: 1 / scaleFactor)
            emailConfirmButton.curvature = 1
            
            animator.addAnimations {
                self.backgroundView.backgroundColor = .iftttLightGrey
                
                self.label.alpha = 0 // FIXME: Should mask from left to right along with switch
                
                self.switchControl.isOn = true
                self.switchControl.knob.transform = CGAffineTransform(scaleX: scaleFactor, y: scaleFactor)
                self.switchControl.knob.curvature = 0
                self.switchControl.alpha = 0
                
                self.backgroundView.layoutIfNeeded() // Move the emailConfirmButton along with the switch
                
                self.emailConfirmButton.transform = .identity
                self.emailConfirmButton.curvature = 0
                self.emailConfirmButton.alpha = 1
                
                self.emailEntryField.alpha = 1
            }
            animator.addCompletion { (_) in
                // Keep the knob is a "clean" state since we don't animate backwards from this step
                self.switchControl.knob.transform = .identity
                self.switchControl.knob.curvature = 1
                
                self.emailEntryField.becomeFirstResponder()
            }
            
        case (.email, .step(let service, let message, let selectIsEnabled)): // Email to step progress
            selectGesture.isEnabled = selectIsEnabled
            progressBar.configure(with: service)
            animator.addAnimations {
                self.emailEntryField.alpha = 0
                self.emailConfirmButton.alpha = 0
                self.emailConfirmButton.backgroundColor = .iftttGrey
                
                self.backgroundView.backgroundColor = .iftttGrey
                
                self.label.configure(message)
                self.label.alpha = 1
            }
            animator.addCompletion { (_) in
                self.emailConfirmButton.backgroundColor = .iftttBlack
                self.emailConfirmButton.transform = .identity
            }
            
        case (.step, .step(_, let message, let selectIsEnabled)): // Changing the message during a step
            selectGesture.isEnabled = selectIsEnabled
            animator.addAnimations {
                self.label.configure(message)
            }
            
        case (.step, .stepComplete(let service)): // Completing a step
            label.alpha = 0 // FIXME: Animate text
            
            backgroundView.backgroundColor = service?.brandColor.contrasting() ?? .iftttBlack
            
            checkmark.alpha = 1
            checkmark.outline.transform = CGAffineTransform(scaleX: 0, y: 0)
            animator.addAnimations {
                self.progressBar.alpha = 0
                self.checkmark.outline.transform = .identity
            }
            animator.addCompletion { (_) in
                self.progressBar.alpha = 1
                self.progressBar.fractionComplete = 0
            }
            checkmark.drawCheckmark(duration: 1.25)
            
        case (.stepComplete, .step(let service, let message, let selectIsEnabled)): // Starting next step
            selectGesture.isEnabled = selectIsEnabled
            progressBar.configure(with: service)
            label.transform = CGAffineTransform(translationX: 20, y: 0)
            animator.addAnimations {
                self.label.configure(message)
                self.label.alpha = 1
                self.label.transform = .identity
                
                self.backgroundView.backgroundColor = service?.brandColor ?? .iftttGrey
                
                self.serviceIconView.set(imageURL: service?.colorIconURL)
                self.serviceIconView.alpha = 1
                
                self.checkmark.alpha = 0
            }
            
        case (.stepComplete, .toggle(let service, let message, let isOn)) where isOn == true: // Transition back to toggle after completed a flow
            switchControl.primeAnimation_centerKnob()
            animator.addAnimations {
                self.serviceIconView.alpha = 0
                
                self.backgroundView.backgroundColor = .iftttBlack
                
                self.label.configure(message)
                self.label.alpha = 1
                
                self.switchControl.configure(with: service)
                self.switchControl.alpha = 1
                self.switchControl.isOn = true
                
                self.checkmark.alpha = 0
            }
            
        default:
            fatalError("Connect button state transition is invalid")
        }
        return animator
    }
}
