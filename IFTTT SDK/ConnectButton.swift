//
//  ConnectButton.swift
//  IFTTT SDK
//
//  Copyright © 2019 IFTTT. All rights reserved.
//

import UIKit

/// Delegate methods for performing any tracking of events from the ConnectButton.
protocol ConnectButtonAnalyticsDelegate: class {
    /// Called when the user is shown the suggested email address.
    func trackSuggestedEmailImpression()
}

// MARK: - Connect Button

@IBDesignable
public class ConnectButton: UIView {
    
    /// Adjust the button's style
    private var style: Style {
        didSet {
            updateStyle()
        }
    }
    
    /// Network controller responsible to loading images from a URL to an UIImageView.
    /// This controller is responsible for serving service icons
    var imageViewNetworkController: ImageViewNetworkController?
    
    private var minimumFooterHeightConstraint: NSLayoutConstraint?
    
    /// Ensures that the button's footer is always a minimum height
    /// This debounces layout changes if the number of lines in the footer changes
    var minimumFooterLabelHeight: CGFloat = 0 {
        didSet {
            minimumFooterHeightConstraint?.constant = minimumFooterLabelHeight
        }
    }
    
    /// The analytics delegate for this connect button.
    weak var analyticsDelegate: ConnectButtonAnalyticsDelegate?
    
    ///
    /// Create a `Connection`'s connect button. This is primarily an internal type. This is the only public method. Use with `ConnectButtonController`.
    ///
    public init() {
        style = .light
        super.init(frame: .zero)
        createLayout()
        updateStyle()
    }
    
    public override init(frame: CGRect) {
        style = .light
        super.init(frame: frame)
        createLayout()
        updateStyle()
    }
    
    required init?(coder aDecoder: NSCoder) {
        style = .light
        super.init(coder: aDecoder)
        createLayout()
        updateStyle()
    }
    
    /// Creates a `UIViewPropertyAnimator` for the provided transition.
    ///
    /// - Parameter transition: The `Transition` to animate to.
    /// - Returns: A `UIViewPropertyAnimator` configured for the transition.
    func animator(for transition: Transition) -> UIViewPropertyAnimator {
        let animator = UIViewPropertyAnimator(duration: transition.duration, curve: .easeInOut)
        if let state = transition.state {
            // We currently can't support interrupting animations with other touch events
            // Animations must complete before we will respond to the next event
            // Note: This does not effect dragging the toggle since any ongoing touch events will continue
            animator.isUserInteractionEnabled = false
            animation(for: state, with: animator)
        }
        
        if let footerValue = transition.footerValue {
            footerLabelAnimator.transition(updatedValue: footerValue,
                                           addingTo: animator)
        }
        
        return animator
    }
    
    
    // MARK: - Interaction
    
    /// The interaction for tapping or dragging the connect button on and off.
    var toggleInteraction = ToggleInteraction() {
        didSet {
            updateInteraction()
        }
    }
    
    /// The interaction for email address entry.
    var emailInteraction = EmailInteraction()
    
    /// Shakes email horizontally to give a visual indication that it is invalid
    func performInvalidEmailAnimation() {
        let animator = UIViewPropertyAnimator.runningPropertyAnimator(withDuration: 0.1, delay: 0.0, options: [], animations: {
            self.backgroundView.transform = CGAffineTransform(translationX: -10, y: 0)
        }) { _ in
            
            let animator = UIViewPropertyAnimator(duration: 0.3,
                                                  timingParameters: UISpringTimingParameters(mass: 1, stiffness: 1000, damping: 7, initialVelocity: .zero))
            animator.addAnimations {
                self.backgroundView.transform = .identity
            }
            
            animator.startAnimation()
        }

        animator.startAnimation()
    }
    
    var footerInteraction = SelectInteraction() {
        didSet {
            updateInteraction()
        }
    }
    
    private lazy var toggleTapGesture = SelectGestureRecognizer(target: self, action: #selector(handleSwitchTap(_:)))
    
    private lazy var toggleDragGesture = UIPanGestureRecognizer(target: self, action: #selector(handleSwitchDrag(_:)))
    
    private lazy var footerSelection = Selectable(footerLabelAnimator.primary.view) { [weak self] in
        self?.footerInteraction.onSelect?()
    }
    
    private var currentToggleAnimation: UIViewPropertyAnimator?
    
    private func getToggleAnimation(isTap: Bool) -> UIViewPropertyAnimator? {
        if currentToggleAnimation != nil {
            return currentToggleAnimation
        }
        
        let transition = isTap ? toggleInteraction.toggleTapTransition : toggleInteraction.toggleDragTransition
        guard let value = transition?() else {
            return nil
        }
        
        let animator = self.animator(for: value)
        animator.addCompletion { position in
            if position == .end {
                let toggleClosure = isTap ? self.toggleInteraction.onToggleTap : self.toggleInteraction.onToggleDrag
                toggleClosure?()
            }
            
            if position == .start {
                let reverseClosure = isTap ? self.toggleInteraction.onReverseTap : self.toggleInteraction.onReverseDrag
                reverseClosure?()
            }
        }
        return animator
    }
    
    @objc private func handleSwitchTap(_ gesture: SelectGestureRecognizer) {
        if gesture.state == .ended {
            if let animation = getToggleAnimation(isTap: true) {
                animation.startAnimation()
                currentToggleAnimation = nil
            }
        }
    }
    
    @objc private func handleSwitchDrag(_ gesture: UIPanGestureRecognizer) {
        guard let animation = getToggleAnimation(isTap: false) else {
            return
        }
        currentToggleAnimation = animation
        
        let location = gesture.location(in: switchControl).x
        var progress = location / switchControl.bounds.width
        if switchControl.isOn == false {
            progress = 1 - progress
        }
        let v = gesture.velocity(in: switchControl).x / switchControl.bounds.width
        
        switch gesture.state {
        case .possible:
            break
        case .began:
            animation.startAnimation()
            animation.pauseAnimation()
        
        case .changed:
            // The animation will automatically finish if it hits 0 or 1
            animation.fractionComplete = max(0.001, min(0.999, progress))
            
        case .ended:
            // Decide if we should reverse the transition
            // switchControl.isOn gives us the value that we are animating towards
            if toggleInteraction.resistance.shouldReverse(switchOn: switchControl.isOn, velocity: v, progress: progress) {
                animation.isReversed = true
            }
            let timing = UISpringTimingParameters(dampingRatio: 1,
                                                  initialVelocity: CGVector(dx: v, dy: 0))
            self.isUserInteractionEnabled = false
            animation.continueAnimation(withTimingParameters: timing, durationFactor: 1)
            animation.addCompletion { [weak self] _ in
                self?.isUserInteractionEnabled = true
            }
            currentToggleAnimation = nil
            
        case .cancelled, .failed:
            animation.isReversed = true
            let timing = UISpringTimingParameters(dampingRatio: 1,
                                                  initialVelocity: CGVector(dx: v, dy: 0))
            animation.continueAnimation(withTimingParameters: timing, durationFactor: 1)
            currentToggleAnimation = nil
        @unknown default:
            assertionFailure("A future unexpected case has been added. We need to update the SDK to handle this.")
            break
        }
    }
    
    private func setupInteraction() {
        switchControl.addGestureRecognizer(toggleTapGesture)
        
        toggleTapGesture.delaysTouchesBegan = true
        toggleTapGesture.delegate = self

        switchControl.knob.addGestureRecognizer(toggleDragGesture)
        toggleDragGesture.delegate = self
        
        emailConfirmButton.onSelect { [weak self] in
            self?.confirmEmail()
        }
        emailEntryField.delegate = self
    }
    
    private func updateInteraction() {
        toggleTapGesture.isEnabled = toggleInteraction.isTapEnabled
        toggleDragGesture.isEnabled = toggleInteraction.isDragEnabled
        footerSelection.isEnabled = footerInteraction.isTapEnabled
    }
    
    private func confirmEmail() {
        let _ = emailEntryField.resignFirstResponder()
        emailInteraction.onConfirm?(emailEntryField.text ?? "")
    }
    
    
    // MARK: - UI
    
    private func updateStyle() {
        backgroundColor = .clear
        
        switch style {
        case .light:
            applyLightStyle()
        }
    }
    
    /// When this button is configured in a Storyboard / NIB, this defines the preview state
    public override func prepareForInterfaceBuilder() {
        backgroundView.backgroundColor = .black
        switchControl.alpha = 1
        switchControl.isOn = false
        switchControl.knob.backgroundColor = Color.blue
        primaryLabelAnimator.configure(.text("Connect"), insets: .avoidLeftKnob)
        let initialFooterText = NSMutableAttributedString(string: "Powered by IFTTT", attributes: [.font : UIFont.footnote(weight: .bold)])
        footerLabelAnimator.configure(.attributed(initialFooterText))
    }
    
    private let backgroundView = PillView()
    
    // MARK: Email view
    
    /// If using the email step, configure the entry field.
    ///
    /// - Parameters:
    ///   - placeholderText: The placeholder text for the email field when it is empty
    ///   - confirmButtonImage: The image asset to use for the email confirm button
    func configureEmailField(placeholderText: String, confirmButtonAsset: UIImage) {
        emailEntryField.placeholder = placeholderText
        emailConfirmButton.imageView.image = confirmButtonAsset
    }
    
    /// The container view for the email button
    /// Provide a "track" on which the button is animated
    /// This scopes effects of layoutIfNeeded
    private let emailConfirmButtonTrack = PassthroughView()
    
    private let emailConfirmButton = PillButton(UIImage())
    
    private let emailEntryField: UITextField = {
        let field = UITextField(frame: .zero)
        field.keyboardType = .emailAddress
        field.autocapitalizationType = .none
        field.returnKeyType = .done
        field.font = Style.Font.email
        field.textColor = Color.mediumGrey
        return field
    }()
    
    // MARK: Text
    
    private let primaryLabelAnimator = LabelAnimator {
        $0.textAlignment = .center
        $0.textColor = .white
        $0.font = Style.Font.connect
        $0.adjustsFontSizeToFitWidth = true
        $0.baselineAdjustment = .alignCenters
    }
    
    private let footerLabelAnimator = LabelAnimator {
        $0.numberOfLines = 1
        $0.textAlignment = .center
        $0.lineBreakMode = .byTruncatingMiddle
    }    
    
    // MARK: Progress bar
    
    private let progressBar = ProgressBar()
    
    // MARK: Switch control
    
    private let switchControl = SwitchControl()
    
    // MARK: Checkmark view
    
    private let checkmark = CheckmarkView()
    
    
    // MARK: Layout
    
    /// A key used by an app to determine if it should hide the footer on the Connect Button.
    static let shouldHideFooterUserDefaultsKey = "appShouldHideConnectButtonFooter"
    
    private func createLayout() {
        
        // In some cases, we need to hide the footer on the Connect Button SDK. Introducing a key check to determine if the footer should be shown.
        let shouldHideFooter = UserDefaults.standard.bool(forKey: ConnectButton.shouldHideFooterUserDefaultsKey)
        
        let stackView: UIStackView
        
        if shouldHideFooter {
            stackView = UIStackView(arrangedSubviews: [backgroundView])
        } else {
            let footerLabel = footerLabelAnimator.primary.view
            
            // Supports minimum footer height
            let footerLabelContainer = UIView()
            footerLabelContainer.addSubview(footerLabel)
            
            // Lock it in place below the button
            footerLabel.constrain.edges(to: footerLabelContainer, edges: [.left, .top, .right])
            
            // But allow it to be shorter than its container
            footerLabel.bottomAnchor.constraint(lessThanOrEqualTo: footerLabelContainer.bottomAnchor)
            let breakableBottomConstraint = footerLabel.bottomAnchor.constraint(equalTo: footerLabelContainer.bottomAnchor)
            breakableBottomConstraint.priority = .defaultHigh
            
            // Ask the label to keep its intrinsic height
            footerLabel.setContentHuggingPriority(.required, for: .vertical)
            
            // Finally ensure the container never goes below the minimum height
            minimumFooterHeightConstraint = footerLabelContainer.heightAnchor.constraint(greaterThanOrEqualToConstant: minimumFooterLabelHeight)
            minimumFooterHeightConstraint?.isActive = true
            
            stackView = UIStackView(arrangedSubviews: [backgroundView, footerLabelContainer])
        }

        stackView.axis = .vertical
        stackView.spacing = Layout.buttonFooterSpacing
        
        addSubview(stackView)
        stackView.constrain.edges(to: self, edges: [.top])
        
        // Center the button but with just less than required priority
        // This prevents it from interfering with `_UITemporaryLayoutHeight` during setup
        let centerXConstraint = stackView.centerXAnchor.constraint(equalTo: centerXAnchor)
        centerXConstraint.priority = UILayoutPriority(UILayoutPriority.required.rawValue - 1)
        centerXConstraint.isActive = true
        
        let centerYConstraint = stackView.centerYAnchor.constraint(equalTo: centerYAnchor)
        centerYConstraint.priority = UILayoutPriority(UILayoutPriority.required.rawValue - 1)
        centerYConstraint.isActive = true
        
        // By defaut, the ConnectButton contents are the full width of the button's view
        // But set a maximum width
        // Set the left anchor to break its constraint if the max width is exceeded
        let leftConstraint = stackView.leftAnchor.constraint(equalTo: layoutMarginsGuide.leftAnchor)
        leftConstraint.priority = UILayoutPriority(UILayoutPriority.required.rawValue - 2)
        leftConstraint.isActive = true
        
        // Fallback to the max width
        // If we don't have this then the button will fit exactly to its content
        let maxWidth = stackView.widthAnchor.constraint(equalToConstant: Layout.maximumWidth)
        maxWidth.priority = .defaultHigh
        maxWidth.isActive = true
        
        // Finally set the max width
        stackView.widthAnchor.constraint(lessThanOrEqualToConstant: Layout.maximumWidth).isActive = true
        
        if !shouldHideFooter {
            addSubview(footerLabelAnimator.transition.view)
            footerLabelAnimator.transition.view.constrain.edges(to: footerLabelAnimator.primary.view, edges: [.left, .top, .right])
        } 
        
        backgroundView.addSubview(progressBar)
        backgroundView.addSubview(primaryLabelAnimator.primary.view)
        backgroundView.addSubview(primaryLabelAnimator.transition.view)
        backgroundView.addSubview(emailEntryField)
        backgroundView.addSubview(checkmark)
        backgroundView.addSubview(switchControl)
        backgroundView.addSubview(emailConfirmButtonTrack)
        emailConfirmButtonTrack.addSubview(emailConfirmButton)
        
        backgroundView.heightAnchor.constraint(equalToConstant: Layout.height).isActive = true
        
        progressBar.constrain.edges(to: backgroundView)
        
        primaryLabelAnimator.primary.view.constrain.edges(to: backgroundView)
        primaryLabelAnimator.transition.view.constrain.edges(to: backgroundView)
        
        emailEntryField.constrain.edges(to: backgroundView, inset: UIEdgeInsets(top: Layout.emailFieldOffset, left: LabelAnimator.Insets.standard.left, bottom: 0, right: LabelAnimator.Insets.avoidRightKnob.right))
        
        // In animations involving the email confirm button, it always tracks along with the switch knob
        emailConfirmButtonTrack.constrain.edges(to: backgroundView)
        emailConfirmButton.constrain.center(in: switchControl.knob)
        emailConfirmButton.constrain.square(length: Layout.height)
        
        switchControl.constrain.edges(to: backgroundView)
        
        checkmark.constrain.center(in: backgroundView)
        
        [switchControl, emailEntryField, emailConfirmButton, checkmark].forEach {
            $0.alpha = 0
        }
        
        setupInteraction()
    }
    
    // MARK: - Loading Animation
    
    private var pulseAnimation: UIViewPropertyAnimator?
    
    private enum PulseAnimationAlpha: CGFloat {
        case full = 1.0
        case partial = 0.4
        
        var reverse: PulseAnimationAlpha {
            switch self {
            case .full:
                return .partial
            case .partial:
                return .full
            }
        }
    }
    
    private func pulseAnimateLabel(toAlpha alpha: PulseAnimationAlpha) {
        self.pulseAnimation = UIViewPropertyAnimator.runningPropertyAnimator(withDuration: 1.2, delay: 0.0, options: [.curveLinear, .repeat], animations: {
            self.primaryLabelAnimator.primary.label.alpha = alpha.rawValue
        }) { _ in
            self.pulseAnimateLabel(toAlpha: alpha.reverse)
        }
    }
    
    private func stopPulseAnimation() {
        pulseAnimation?.stopAnimation(true)
        pulseAnimation = nil
    }
}

// MARK: Gesture recognizer delegate (Toggle interaction)

extension ConnectButton: UIGestureRecognizerDelegate {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        // Prevents the tap gesture from interfering with scrolling when it is placed in a scroll view
        // We don't want this behavior for the toggle drag gesture. The scroll view should not move when the user is dragging the toggle.
        return self.toggleTapGesture == gestureRecognizer
    }
}

// MARK: Text field delegate (email)

extension ConnectButton: UITextFieldDelegate {
    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        confirmEmail()
        return true
    }
}

// MARK: Progress bar

extension ConnectButton: ProgressBar {
    func showProgress(from start: CGFloat = 0, to end: CGFloat = 1,
                      duration: TimeInterval, curve: UIView.AnimationCurve = .linear) -> UIViewPropertyAnimator {
        progressBar.fractionComplete = start
        return UIViewPropertyAnimator(duration: duration, curve: curve) {
            self.progressBar.fractionComplete = end
        }
    }
}

// MARK: Button state

private extension ConnectButton {
    
    private func animation(for animationState: AnimationState, with animator: UIViewPropertyAnimator) {
        switch animationState {
        case let .loading(message):
            transitionToLoading(message: message, animator: animator)
            
        case .loadingFailed:
            transitionToLoadingFailed()
            
        case let .connect(service, message):
            transitionToConnect(service: service, message: message, animator: animator)
            
        case let .createAccount(message):
            primaryLabelAnimator.transition(updatedValue: .text(message), insets: .standard, addingTo: animator)
            
        case let .slideToDisconnect(message):
            transitionToSlideToDisconnect(message: message, animator: animator)
            
        case let .disconnecting(message):
            transitionToDisconnecting(message: message, animator: animator)
            
        case let .slideToConnect(service, message):
            transitionToSlideToConnect(isOn: true, service: service, labelValue: .text(message), animator: animator)
            
        case let .enterEmail(service, suggestedEmail):
            transitionToEmail(service: service, suggestedEmail: suggestedEmail, animator: animator)
            
        case let .verifying(message):
            transitionToVerifying(message: message, animator: animator)
            
        case let .continueToService(service, message):
            transitionToContinueToService(service: service, message: message, animator: animator)
            
        case let .connecting(service, message):
            transitionToConnecting(service: service, message: message, animator: animator)
            
        case let .checkmark(service):
            transitionToCheckmark(service: service, animator: animator)
            
        case let .connected(service, message, shouldAnimateKnob):
            transitionToConnected(service: service, message: message, shouldAnimateKnob: shouldAnimateKnob, animator: animator)
            
        case let .disconnected(message):
            transitionToDisconnected(message: message, animator: animator)
        }
    }
    
    private func transitionToLoading(message: String, animator: UIViewPropertyAnimator) {
        stopPulseAnimation()
        
        primaryLabelAnimator.configure(.text(message), insets: .standard)
        
        animator.addAnimations {
            self.backgroundView.backgroundColor = .black
        }
        
        pulseAnimateLabel(toAlpha: .partial)
    }
    
    private func transitionToLoadingFailed() {
        stopPulseAnimation()
        resetEmailState()
    }
    
    private func resetEmailState() {
        emailEntryField.text = nil
        emailEntryField.alpha = 0.0
        emailConfirmButton.transform = .identity
        emailConfirmButton.maskedEndCaps = .all
        emailConfirmButton.alpha = 0
    }
    
    private func transitionToConnect(service: Service, message: String, animator: UIViewPropertyAnimator) {
        stopPulseAnimation()
        let trackColor: UIColor = .black
        primaryLabelAnimator.transition(updatedValue: .text(message), insets: .avoidLeftKnob, addingTo: animator)
        switchControl.configure(with: service, networkController: self.imageViewNetworkController, trackColor: trackColor)
        emailConfirmButton.backgroundColor = service.brandColor
        
        resetEmailState()
        
        animator.addAnimations {
            self.progressBar.alpha = 0
            self.backgroundView.backgroundColor = trackColor
            self.switchControl.isOn = false
            self.switchControl.knob.alpha = 1
            self.switchControl.knob.maskedEndCaps = .all
            self.switchControl.knob.iconView.alpha = 1
            self.switchControl.knob.layer.shadowOpacity = 0.25
            self.switchControl.alpha = 1
            
            // This is only relevent for dark mode when we draw a border around the switch
            self.backgroundView.border.opacity = 1
        }
    }
    
    /// The toggle transition from initial or reconnect to a message about activating the connection
    private func transitionToSlideToConnect(isOn: Bool,
                                            service: Service?,
                                            labelValue: LabelValue,
                                            animator: UIViewPropertyAnimator) {
        
        primaryLabelAnimator.transition(updatedValue: labelValue,
                                        insets: .standard,
                                        addingTo: animator)
        
        progressBar.configure(with: service)
        progressBar.fractionComplete = 0
        progressBar.alpha = 1
        
        animator.addAnimations {
            self.switchControl.isOn = isOn
            self.switchControl.knob.iconView.alpha = 0
            self.switchControl.knob.backgroundColor = service?.brandColor ?? .black
            self.switchControl.knob.layer.shadowOpacity = 0
            
            self.backgroundView.backgroundColor = service?.brandColor ?? .black
        }
        
        animator.addCompletion { position in
            switch position {
            case .start:
                self.switchControl.isOn = !isOn
                self.switchControl.knob.layer.shadowOpacity = 0.25
            case .end:
                self.switchControl.alpha = 0
            case .current:
                break
            @unknown default:
                assertionFailure("A future unexpected case has been added. We need to update the SDK to handle this.")
                break
            }
        }
    }
    
    private func transitionToEmail(service: Service, suggestedEmail: String?, animator: UIViewPropertyAnimator, shouldBecomeFirstResponder: Bool = false) {
        let email = emailEntryField.text?.isEmpty != true ? emailEntryField.text : suggestedEmail
        let scaleFactor = Layout.height / Layout.knobDiameter
        let trackColor = Color.lightGrey
        emailEntryField.text = email
        
        emailConfirmButton.transform = CGAffineTransform(scaleX: 1 / scaleFactor, y: 1 / scaleFactor)
        emailConfirmButton.maskedEndCaps = .all // Match the switch knob at the start of the animation
        
        primaryLabelAnimator.transition(updatedValue: .none,
                                        addingTo: animator)
        
        progressBar.configure(with: nil)
        progressBar.alpha = 0
        
        emailEntryField.alpha = 0
        animator.addAnimations {
            self.backgroundView.backgroundColor = trackColor
            self.switchControl.isOn = true
            self.switchControl.knob.layer.shadowOpacity = 0.0
            // This is only relevent for dark mode when we draw a border around the switch
            self.backgroundView.border.opacity = 0
            self.emailConfirmButtonTrack.layoutIfNeeded() // Move the emailConfirmButton along with the switch
            self.emailConfirmButton.transform = .identity
            self.emailConfirmButton.maskedEndCaps = .right
        }
        
        animator.addAnimations({
            self.switchControl.knob.maskedEndCaps = .right // Morph into the email button
            self.switchControl.knob.iconView.alpha = 0
            self.switchControl.knob.transform = CGAffineTransform(scaleX: scaleFactor, y: scaleFactor)
        }, delayFactor: 0.25)
        
        animator.addAnimations({
            self.emailConfirmButton.alpha = 1
            self.emailEntryField.alpha = 1
        }, delayFactor: 0.7)
        
        let resetKnob = {
            // Keep the knob is a "clean" state since we don't animate backwards from this step
            self.switchControl.knob.transform = .identity
            self.switchControl.knob.maskedEndCaps = .all // reset
            self.switchControl.knob.layer.shadowOpacity = 0.25
            self.switchControl.configure(with: service, networkController: self.imageViewNetworkController, trackColor: trackColor)
            self.switchControl.knob.iconView.alpha = 1.0
        }
        
        animator.addCompletion { position in
            
            switch position {
            case .start:
                resetKnob()
                self.emailEntryField.alpha = 0.0
                
                self.switchControl.isOn = false
                self.switchControl.alpha = 1
                
                self.progressBar.alpha = 0
                self.backgroundView.backgroundColor = .black
                
                self.emailConfirmButton.transform = .identity
                self.emailConfirmButton.maskedEndCaps = .all
                self.emailConfirmButton.alpha = 0
                
                // This is only relevent for dark mode when we draw a border around the switch
                self.backgroundView.border.opacity = 1
            case .end:
                let endAnimator = UIViewPropertyAnimator(duration: 0.25, curve: .easeOut) {
                    self.switchControl.alpha = 0
                }
                
                endAnimator.addCompletion { _ in
                    if suggestedEmail == nil || shouldBecomeFirstResponder {
                        self.emailEntryField.becomeFirstResponder()
                    }
                    self.analyticsDelegate?.trackSuggestedEmailImpression()
                    resetKnob()
                }
                
                endAnimator.startAnimation()
                
            default:
                break
            }
        }
    }
    
    private func transitionToVerifying(message: String, animator: UIViewPropertyAnimator) {
        primaryLabelAnimator.transition(updatedValue: .text(message), insets: .standard, addingTo: animator)
        
        progressBar.configure(with: nil)
        progressBar.alpha = 1
        
        animator.addAnimations {
            self.emailEntryField.alpha = 0
            self.emailConfirmButton.alpha = 0
            self.backgroundView.backgroundColor = .black
            
            // This is only relevent for dark mode when we draw a border around the switch
            self.backgroundView.border.opacity = 1
        }
        
        animator.addCompletion { _ in
            self.emailConfirmButton.transform = .identity
        }
    }
    
    private func transitionToContinueToService(service: Service, message: String, animator: UIViewPropertyAnimator) {
        primaryLabelAnimator.transition(updatedValue: .text(message), insets: .standard, addingTo: animator)
        
        progressBar.configure(with: service)
        
        animator.addAnimations {
            self.backgroundView.backgroundColor = service.brandColor
        }
    }
    
    private func transitionToCheckmark(service: Service, animator: UIViewPropertyAnimator) {
        primaryLabelAnimator.transition(updatedValue: .none, addingTo: animator)
        
        backgroundView.backgroundColor = service.brandColor
        
        checkmark.alpha = 1
        checkmark.outline.transform = CGAffineTransform(scaleX: 0, y: 0)
        
        animator.addAnimations {
            self.progressBar.alpha = 0
            self.checkmark.outline.transform = .identity
        }
        
        animator.addCompletion { _ in
            self.progressBar.alpha = 1
            self.progressBar.fractionComplete = 0
        }
        
        checkmark.drawCheckmark(duration: 1.25)
    }
    
    private func transitionToConnecting(service: Service, message: String, animator: UIViewPropertyAnimator) {
        primaryLabelAnimator.transition(updatedValue: .text(message), insets: .standard, addingTo: animator)
    
        backgroundView.backgroundColor = service.brandColor
        switchControl.knob.iconView.alpha = 1
        switchControl.knob.transform = .identity
        switchControl.knob.maskedEndCaps = .all
 
        progressBar.configure(with: service)
        progressBar.alpha = 1
        
        // We don't show messages and the switch at the same time
        switchControl.alpha = 0
    }
    
    private func transitionToConnected(service: Service, message: String, shouldAnimateKnob: Bool, animator: UIViewPropertyAnimator) {
        stopPulseAnimation() // If we Cancelled disconnect
        
        primaryLabelAnimator.transition(updatedValue: .text(message), insets: .avoidRightKnob, addingTo: animator)
        
        progressBar.configure(with: service)
        progressBar.fractionComplete = 0
        
        if shouldAnimateKnob {
            switchControl.primeAnimation_centerKnob()
            animator.addAnimations {
                self.switchControl.isOn = true
            }
        } else {
            switchControl.isOn = true
        }
        
        animator.addAnimations {
            let trackColor: UIColor = .black
            self.backgroundView.backgroundColor = trackColor
            
            self.switchControl.configure(with: service, networkController: self.imageViewNetworkController, trackColor: trackColor)
            self.switchControl.alpha = 1
            self.switchControl.knob.alpha = 1
            self.switchControl.knob.iconView.alpha = 1
            self.checkmark.alpha = 0
            // Animate the checkmark along with the knob from the center position to the knob's final position
            let knobOffsetFromCenter = 0.5 * self.backgroundView.bounds.width - Layout.knobInset - 0.5 * Layout.knobDiameter
            self.checkmark.transform = CGAffineTransform(translationX: knobOffsetFromCenter, y: 0)
        }
        
        animator.addCompletion { _ in
            self.checkmark.transform = .identity
        }
    }
    
    private func transitionToSlideToDisconnect(message: String, animator: UIViewPropertyAnimator) {
        primaryLabelAnimator.transition(updatedValue: .text(message),
                                        insets: .avoidRightKnob,
                                        addingTo: animator)
        pulseAnimateLabel(toAlpha: .partial)
    }
    
    private func transitionToDisconnecting(message: String, animator: UIViewPropertyAnimator) {
        primaryLabelAnimator.transition(updatedValue: .text(message),
                                        insets: .standard,
                                        addingTo: animator)
        progressBar.configure(with: nil)
        stopPulseAnimation()
        
        animator.addAnimations {
            self.switchControl.isOn = false
            self.switchControl.knob.iconView.alpha = 0
            self.switchControl.knob.backgroundColor = .black
            self.switchControl.knob.layer.shadowOpacity = 0
        }
        
        animator.addAnimations({
            self.switchControl.alpha = 0
        }, delayFactor: 0.8)
        
        animator.addCompletion { position in
            switch position {
            case .start:
                self.switchControl.isOn = true
                self.switchControl.knob.layer.shadowOpacity = 0.25
            case .end:
                self.switchControl.alpha = 0
            case .current:
                break
            @unknown default:
                assertionFailure("A future unexpected case has been added. We need to update the SDK to handle this.")
                break
            }
        }
    }
    
    private func transitionToDisconnected(message: String, animator: UIViewPropertyAnimator) {
        primaryLabelAnimator.transition(updatedValue: .text(message),
                                        insets: .standard,
                                        addingTo: animator)
    }
    
    private func applyLightStyle() {
        emailConfirmButton.backgroundColor = .black
        emailConfirmButton.imageView.tintColor = .white
        emailConfirmButton.layer.shadowColor = UIColor.clear.cgColor
        
        footerLabelAnimator.primary.label.textColor = style.footerColor
        footerLabelAnimator.transition.label.textColor = style.footerColor
        
        backgroundView.border = .init(color: .clear, width: Layout.borderWidth)
    }
    
    private func applyDarkStyle() {
        emailConfirmButton.backgroundColor = .white
        emailConfirmButton.imageView.tintColor = .black
        // Add a shadow to the left side of the button to delineate it from the email field background
        let layer = emailConfirmButton.layer
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.2
        layer.shadowRadius = 5
        layer.shadowOffset = CGSize(width: -2, height: 0)
        
        footerLabelAnimator.primary.label.textColor = style.footerColor
        footerLabelAnimator.transition.label.textColor = style.footerColor
        
        backgroundView.border = .init(color: Color.border, width: Layout.borderWidth)
    }
    
    private func updateKnobForLightStyle() {
        switchControl.knob.backgroundColor = .black
    }
    
    private func updateKnobForDarkStyle() {
        switchControl.knob.backgroundColor = .white
    }
}
