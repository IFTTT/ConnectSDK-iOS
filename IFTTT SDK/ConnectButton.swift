//
//  ConnectButton.swift
//  IFTTT SDK
//
//  Created by Jon Chmura on 8/31/18.
//  Copyright © 2018 IFTTT. All rights reserved.
//

import UIKit
import UIKit.UIGestureRecognizerSubclass

// Layout constants

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


// MARK: - Connect Button

//@IBDesignable
public class ConnectButton: UIView {
    
    public init() {
        super.init(frame: .zero)
        createLayout()
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        self.init()
    }
    
    
    // MARK: - Button state
    
    enum State: CustomStringConvertible {
        case
        initialization,
        toggle(for: Applet.Service, message: String, isOn: Bool),
        email(suggested: String?),
        step(for: Applet.Service?, message: String),
        stepComplete(for: Applet.Service?)
        
        struct Transition {
            fileprivate let animator: UIViewPropertyAnimator
            
            func preform(animated: Bool = true) {
                if animated {
                    animator.startAnimation()
                } else {
                    animator.startAnimation()
                    animator.stopAnimation(false)
                    animator.finishAnimation(at: .end)
                }
            }
            func pause() {
                animator.pauseAnimation()
            }
            func set(progress: CGFloat) {
                animator.fractionComplete = max(0.001, min(0.999, progress))
            }
            func resume(with timing: UITimingCurveProvider, duration: TimeInterval?) {
                animator.pauseAnimation()
                var durationFactor: CGFloat = 1
                if let continueDuration = duration {
                    let timeElasped = TimeInterval(1 - animator.fractionComplete) * animator.duration
                    durationFactor = CGFloat((continueDuration + timeElasped) / animator.duration)
                }
                animator.continueAnimation(withTimingParameters: timing, durationFactor: durationFactor)
            }
            func onComplete(_ body: @escaping (() -> Void)) {
                animator.addCompletion { (_) in
                    body()
                }
            }
        }
        
        var description: String {
            switch self {
            case .initialization: return "initialization"
            case .toggle: return "toggle"
            case .email: return "email"
            case .step: return "step"
            case .stepComplete: return "stepComplete"
            }
        }
    }
    
    private(set) var currentState: State = .initialization
    
    func progressTransition(timeout: TimeInterval) -> State.Transition {
        return State.Transition(animator: progressBar.animator(duration: timeout))
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
    
    func configureFooter(_ attributedString: NSAttributedString, animated: Bool) {
        if animated {
            footerLabel.transition(with: .rotateDown, updatedText: .attributed(attributedString))
        } else {
            footerLabel.configure(.attributed(attributedString))
        }
    }
    
    
    
    // MARK: - Interaction
    
    struct ToggleInteraction {
        /// Can the switch be tapped
        var isTapEnabled: Bool = false
        
        /// Can the switch be dragged
        var isDragEnabled: Bool = false
        
        /// What is the next state of the toggle
        var nextToggleState: (() -> State)?
        
        /// Callback when switch is toggled
        /// Sends true if switch has been toggled to the on position
        var onToggle: ((Bool) -> Void)?
    }
    
    struct EmailInteraction {
        /// Callback when the email address is confirmed
        var onConfirm: ((String) -> Void)?
    }
    
    struct StepInteraction {
        var isTapEnabled: Bool = false
        
        var onSelect: (() -> Void)?
    }
    
    var toggleInteraction = ToggleInteraction()
    
    var emailInteraction = EmailInteraction()
    
    var stepInteraction = StepInteraction() {
        didSet {
            updateInteraction()
        }
    }
    
    private class ScrollGestureRecognizer: UIPanGestureRecognizer {
        override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
            // FIXME: Forgot comment here. Don't remember what this does :/
            if (self.state == .began) { return }
            super.touchesBegan(touches, with: event)
            self.state = .began
        }
    }
    
    private lazy var stepSelection = Selectable(backgroundView) { [weak self] in
        self?.stepInteraction.onSelect?()
    }
    
    private lazy var toggleGesture = ScrollGestureRecognizer(target: self, action: #selector(handlePan(_:)))
    
    private var currentToggleTransition: State.Transition?
    
    private func getToggleTransition() -> State.Transition? {
        if currentToggleTransition != nil {
            return currentToggleTransition
        }
        guard
            case .toggle = currentState,
            let nextState = toggleInteraction.nextToggleState?()
        else {
            return nil
        }
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
        case .changed:
            let location = gesture.location(in: switchControl).x
            var progress = location / switchControl.bounds.width
//            transition.set(progress: progress)
//            debugPrint("PROGRESS: \(progress)")
        case .ended:
            transition.preform()
            transition.onComplete {
                if case .toggle(_, _, let isOn) = self.currentState {
                    self.toggleInteraction.onToggle?(isOn)
                }
            }
            currentToggleTransition = nil
        case .cancelled, .failed:
            currentToggleTransition = nil
        }
    }
    
    private func setupInteraction() {
        switchControl.addGestureRecognizer(toggleGesture)
        toggleGesture.delegate = self
        
        emailConfirmButton.onSelect { [weak self] in
            self?.confirmEmail()
        }
        emailEntryField.delegate = self
    }
    
    private func updateInteraction() {
        stepSelection.isEnabled = stepInteraction.isTapEnabled
    }
    
    fileprivate func confirmEmail() {
        let _ = emailEntryField.resignFirstResponder()
        guard let email = emailEntryField.text, email.isValidEmail else {
            // FIXME: Maybe shake the button to indicate the input is invalid
            return
        }
        emailInteraction.onConfirm?(email)
    }
    
    
    // MARK: - UI
    
    fileprivate let backgroundView = PillView()
    
    fileprivate let serviceIconView = UIImageView()
    
    // MARK: Email view
    
    /// The container view for the email button
    /// Provide a "track" on which the button is animated
    /// This scopes effects of layoutIfNeeded
    fileprivate let emailConfirmButtonTrack = PassthroughView()
    
    fileprivate let emailConfirmButton = PillButton(Assets.Button.emailConfirm) {
        $0.imageView.tintColor = .white
        $0.backgroundColor = .black
    }
    
    fileprivate let emailEntryField: UITextField = {
        let field = UITextField(frame: .zero)
        field.placeholder = "button.email.placeholder".localized
        field.keyboardType = .emailAddress
        field.autocorrectionType = .no
        field.autocapitalizationType = .none
        return field
    }()
    
    // MARK: Text
    
    fileprivate let label = AnimatingLabel { (label) in
        label.textAlignment = .center
        label.textColor = .white
        label.font = .ifttt(Typestyle.h4.callout().nonDynamic)
        label.adjustsFontSizeToFitWidth = true
    }
    
    let footerLabel = AnimatingLabel { (label) in
        label.numberOfLines = 0
        label.textAlignment = .center
        label.textColor = .iftttBlack
    }
    
    /// Adds functionality to animate text changes
    class AnimatingLabel: UIView {
        enum Effect {
            case
            crossfade,
            slideInFromRight,
            rotateDown
        }
        enum Value {
            case
            none,
            text(String),
            attributed(NSAttributedString)
            
            func update(label: UILabel) {
                switch self {
                case .none:
                    label.text = nil
                    label.attributedText = nil
                case .text(let text):
                    label.text = text
                case .attributed(let text):
                    label.attributedText = text
                }
            }
            
            var isEmpty: Bool {
                if case .none = self {
                    return true
                }
                return false
            }
        }
        struct Insets {
            let left: CGFloat
            let right: CGFloat
            
            static let zero = Insets(left: 0, right: 0)
            static let standard = AnimatingLabel.Insets(left: 0.5 * Layout.height,
                                                        right: 0.5 * Layout.height)
            
            static let avoidServiceIcon = AnimatingLabel.Insets(left: 0.5 * Layout.height + 0.5 * Layout.serviceIconDiameter + 10,
                                                                right: standard.right)
            
            static func avoidSwitchKnob(isOn: Bool) -> AnimatingLabel.Insets {
                let avoidSwitch = 0.5 * Layout.height + 0.5 * Layout.knobDiameter + 10
                if isOn {
                    return AnimatingLabel.Insets(left: standard.left, right: avoidSwitch)
                } else {
                    return AnimatingLabel.Insets(left: avoidSwitch, right: standard.right)
                }
            }
            
            fileprivate func apply(_ view: AnimatingLabel) {
                view.layoutMargins.left = left
                view.layoutMargins.right = right
            }
        }
        
        func configure(_ value: Value, insets: Insets? = nil) {
            value.update(label: label)
            insets?.apply(self)
        }
        
        func transition(with effect: Effect,
                        updatedText: Value,
                        insets: Insets? = nil,
                        addingTo externalAnimator: UIViewPropertyAnimator? = nil) {
            let defaultAnimator = UIViewPropertyAnimator(duration: 0.3, curve: .easeOut, animations: nil)
            
            switch effect {
            case .crossfade:
                // FIXME: This really isn't quite right
                // Probably won't work as expected for toggling switch
                // We need an animation where the text reveals / hides from left to right
                let animator = externalAnimator ?? defaultAnimator
                if updatedText.isEmpty {
                    animator.addAnimations {
                        self.label.alpha = 0
                    }
                } else {
                    updatedText.update(label: label)
                    label.alpha = 0
                    insets?.apply(self)
                    animator.addAnimations {
                        self.label.alpha = 1
                    }
                }
                if externalAnimator == nil {
                    animator.startAnimation()
                }
                
            case .slideInFromRight:
                updatedText.update(label: label)
                insets?.apply(self)
                label.alpha = 0
                label.transform = CGAffineTransform(translationX: 20, y: 0)
                
                let animator = externalAnimator ?? defaultAnimator
                animator.addAnimations {
                    self.label.transform = .identity
                    self.label.alpha = 1
                }
                if externalAnimator == nil {
                    animator.startAnimation()
                }
                
            case .rotateDown:
                assert(externalAnimator == nil, "Not supported for rotate transitions")
                
                let animator = UIViewPropertyAnimator(duration: 0.2, curve: .easeIn, animations: nil)
                animator.addAnimations {
                    self.label.alpha = 0
                    self.label.transform = CGAffineTransform(translationX: 0, y: 20).scaledBy(x: 0.9, y: 0.9)
                }
                animator.addCompletion { _ in
                    updatedText.update(label: self.label)
                    insets?.apply(self)
                    self.label.transform = CGAffineTransform(translationX: 0, y: -20).scaledBy(x: 0.9, y: 0.9)
                    
                    let nextAnimator = UIViewPropertyAnimator(duration: 0.2, curve: .easeOut) {
                        self.label.alpha = 1
                        self.label.transform = .identity
                    }
                    nextAnimator.startAnimation()
                }
                animator.startAnimation()
            }
        }
        
        /// Diplays the content of this label
        private let label = UILabel()
        
        init(configure: ((UILabel) -> Void)? = nil) {
            super.init(frame: .zero)
            
            layoutMargins = .zero
            
            addSubview(label)
            label.constrain.edges(to: layoutMarginsGuide)
            
            configure?(label)
        }
        @available(*, unavailable)
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
    
    // MARK: Progress bar
    
    fileprivate let progressBar = ProgressBar()
    
    fileprivate class ProgressBar: PassthroughView {
        var fractionComplete: CGFloat = 0 {
            didSet {
                update()
            }
        }
        
        private let bar = PassthroughView()
        
        func configure(with service: Applet.Service?) {
            fractionComplete = 0
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
        let track = PassthroughView()
        
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
        let stackView = UIStackView(arrangedSubviews: [backgroundView, footerLabel])
        stackView.axis = .vertical
        stackView.spacing = 20
        
        addSubview(stackView)
        stackView.constrain.edges(to: self)
        
        backgroundView.addSubview(progressBar)
        backgroundView.addSubview(label)
        backgroundView.addSubview(emailEntryField)
        backgroundView.addSubview(checkmark)
        backgroundView.addSubview(switchControl)
        backgroundView.addSubview(emailConfirmButtonTrack)
        emailConfirmButtonTrack.addSubview(emailConfirmButton)
        backgroundView.addSubview(serviceIconView)
        
        backgroundView.clipsToBounds = true
        backgroundView.heightAnchor.constraint(equalToConstant: Layout.height).isActive = true
        
        progressBar.constrain.edges(to: backgroundView)
        
        label.constrain.edges(to: backgroundView)
        
        emailEntryField.constrain.edges(to: backgroundView,
                                        inset: UIEdgeInsets(top: 0, left: AnimatingLabel.Insets.standard.left,
                                                            bottom: 0, right: AnimatingLabel.Insets.avoidSwitchKnob(isOn: true).right))
        
        // In animations involving the email confirm button, it always tracks along with the switch knob
        emailConfirmButtonTrack.constrain.edges(to: backgroundView)
        emailConfirmButton.constrain.center(in: switchControl.knob)
        emailConfirmButton.constrain.square(length: Layout.height)
        
        switchControl.constrain.edges(to: backgroundView)
        
        checkmark.constrain.center(in: backgroundView)
        
        serviceIconView.constrain.square(length: Layout.serviceIconDiameter)
        serviceIconView.centerYAnchor.constraint(equalTo: backgroundView.centerYAnchor).isActive = true
        serviceIconView.centerXAnchor.constraint(equalTo: backgroundView.leftAnchor, constant: 0.5 * Layout.height).isActive = true
        
        [switchControl, emailEntryField, emailConfirmButton, checkmark, serviceIconView].forEach {
            $0.alpha = 0
        }
        
        setupInteraction()
    }
}

// MARK: Gesture recognizer delegate (Toggle interaction)

extension ConnectButton: UIGestureRecognizerDelegate {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        // Prevents the toggle gesture from interfering with scrolling when it is placed in a scroll view
        return true
    }
}

// MARK: Text field delegate (email)

private extension String {
    var isValidEmail: Bool {
        // FIXME: Use a better REGEX and move this elsewhere.
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

// MARK: Checkmark

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

// MARK: Progress bar

private extension ConnectButton.ProgressBar {
    func animator(duration: TimeInterval) -> UIViewPropertyAnimator {
        fractionComplete = 0
        let animator = UIViewPropertyAnimator(duration: duration, curve: .linear) {
            self.fractionComplete = 1
        }
        return animator
    }
}

// MARK: Button state

private extension ConnectButton {
    var animationDuration: TimeInterval { return 0.5 }
    
    func animator(forTransitionTo state: State, from previousState: State) -> UIViewPropertyAnimator {
        let animator = UIViewPropertyAnimator(duration: animationDuration,
                                              timingParameters: UISpringTimingParameters(dampingRatio: 1,
                                                                                         initialVelocity: .zero))
        switch (previousState, state) {
            
        // Setup switch
        case (.initialization, .toggle(let service, let message, let isOn)):
            self.label.configure(.text(message), insets: .avoidSwitchKnob(isOn: isOn))
            animator.addAnimations {
                self.backgroundView.backgroundColor = .black
                self.switchControl.configure(with: service)
                self.switchControl.isOn = isOn
                self.switchControl.knob.curvature = 1
                self.switchControl.alpha = 1
            }
            
            
        // Change toggle text
        case (.toggle(_, let lastMessage, let wasOn), .toggle(_, let message, let isOn)) where wasOn == isOn:
            if lastMessage != message {
                label.transition(with: .rotateDown,
                                 updatedText: .text(message),
                                 insets: .avoidSwitchKnob(isOn: isOn))
            }
            animator.addAnimations { }
            
            
        // Toggle
        case (.toggle, .toggle(_, let message, let isOn)):
            label.transition(with: .crossfade,
                             updatedText: .text(message),
                             insets: .avoidSwitchKnob(isOn: isOn),
                             addingTo: animator)
            
            progressBar.configure(with: nil)
            progressBar.alpha = 1
            
            animator.addAnimations {
                self.backgroundView.backgroundColor = isOn ? .black : .iftttGrey
                self.switchControl.isOn = isOn
            }
            
            
        // Connect to enter email
        case (.toggle(_, _, let isOn), .email(let suggested)) where isOn == false:
            let scaleFactor = Layout.height / Layout.knobDiameter
            
            emailEntryField.text = suggested
            
            emailConfirmButton.transform = CGAffineTransform(scaleX: 1 / scaleFactor, y: 1 / scaleFactor)
            emailConfirmButton.curvature = 1
            
            label.transition(with: .crossfade,
                             updatedText: .none,
                             addingTo: animator)
            
            progressBar.configure(with: nil)
            
            animator.addAnimations {
                self.backgroundView.backgroundColor = .iftttLightGrey
                
                self.switchControl.isOn = true
                self.switchControl.knob.transform = CGAffineTransform(scaleX: scaleFactor, y: scaleFactor)
                self.switchControl.knob.curvature = 0
                self.switchControl.alpha = 0
                
                self.emailConfirmButtonTrack.layoutIfNeeded() // Move the emailConfirmButton along with the switch
                
                self.emailConfirmButton.transform = .identity
                self.emailConfirmButton.curvature = 0
                self.emailConfirmButton.alpha = 1
                
                self.emailEntryField.alpha = 1
            }
            animator.addCompletion { (_) in
                // Keep the knob is a "clean" state since we don't animate backwards from this step
                self.switchControl.knob.transform = .identity
                self.switchControl.knob.curvature = 1
                
                if suggested == nil {
                    self.emailEntryField.becomeFirstResponder()
                }
            }
        
            
        // Email to step progress
        case (.email, .step(let service, let message)):
            progressBar.configure(with: service)
            
            label.transition(with: .crossfade,
                             updatedText: .text(message),
                             insets: service == nil ? .standard : .avoidServiceIcon,
                             addingTo: animator)
            
            animator.addAnimations {
                self.emailEntryField.alpha = 0
                self.emailConfirmButton.alpha = 0
                self.emailConfirmButton.backgroundColor = .iftttGrey
                
                self.backgroundView.backgroundColor = service?.brandColor ?? .iftttGrey
                
                self.serviceIconView.set(imageURL: service?.colorIconURL)
                self.serviceIconView.alpha = 1
            }
            animator.addCompletion { (_) in
                self.emailConfirmButton.backgroundColor = .black
                self.emailConfirmButton.transform = .identity
            }
            
            
        // Changing the message during a step
        case (.step, .step(_, let message)):
            label.transition(with: .rotateDown, updatedText: .text(message))
            animator.addAnimations { }
            
            
        // Completing a step
        case (.step, .stepComplete(let service)):
            label.transition(with: .rotateDown, updatedText: .none)
            
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
            
        
        // Starting next step
        case (.stepComplete, .step(let service, let message)):
            progressBar.configure(with: service)
            
            label.transition(with: .slideInFromRight,
                             updatedText: .text(message),
                             insets: service == nil ? .standard : .avoidServiceIcon,
                             addingTo: animator)
            
            animator.addAnimations {
                self.backgroundView.backgroundColor = service?.brandColor ?? .iftttGrey
                
                self.serviceIconView.set(imageURL: service?.colorIconURL)
                self.serviceIconView.alpha = 1
                
                self.checkmark.alpha = 0
            }
            
            
        // Transition back to toggle after completed a flow
        case (.stepComplete, .toggle(let service, let message, let isOn)) where isOn == true:
            switchControl.primeAnimation_centerKnob()
            label.transition(with: .crossfade,
                             updatedText: .text(message),
                             insets: .avoidSwitchKnob(isOn: isOn),
                             addingTo: animator)
            progressBar.configure(with: service)
            
            animator.addAnimations {
                self.serviceIconView.alpha = 0
                
                self.backgroundView.backgroundColor = .black
                
                self.switchControl.configure(with: service)
                self.switchControl.alpha = 1
                self.switchControl.isOn = true
                
                self.checkmark.alpha = 0
            }
            
            
        // Abort a flow
        case (.step, .toggle(let service, let message, let isOn)) where isOn == false:
            label.transition(with: .rotateDown, updatedText: .text(message), insets: .avoidSwitchKnob(isOn: isOn))
            progressBar.configure(with: service)
            
            animator.addAnimations {
                self.backgroundView.backgroundColor = .black
                self.switchControl.configure(with: service)
                self.switchControl.isOn = isOn
                self.switchControl.knob.curvature = 1
                self.switchControl.alpha = 1
                
                self.serviceIconView.alpha = 0
            }
            
        default:
            fatalError("Connect button state transition from \(previousState) to \(state) is invalid")
        }
        return animator
    }
}
