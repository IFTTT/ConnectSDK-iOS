//
//  ConnectButton.swift
//  IFTTT SDK
//
//  Created by Jon Chmura on 8/31/18.
//  Copyright © 2018 IFTTT. All rights reserved.
//

import UIKit

// Layout constants

fileprivate struct Layout {
    static let height: CGFloat = 64
    static let maximumWidth = 6 * height
    static let knobInset: CGFloat = 6
    static let knobDiameter = height - 2 * knobInset
    static let checkmarkDiameter: CGFloat = 42
    static let checkmarkLength: CGFloat = 14
    static let serviceIconDiameter = 0.5 * knobDiameter
    static let borderWidth: CGFloat = 2.5
    static let buttonFooterSpacing: CGFloat = 20
}


// MARK: - Connect Button

@available(iOS 10.0, *)
@IBDesignable
public class ConnectButton: UIView {
    
    /// Adjusts the button for a white or black background
    ///
    /// - light: Style the button for a white background (Default)
    /// - dark: Style the button for a black background
    public enum Style {
        case light
        case dark
        
        fileprivate struct Font {
            static let connect = UIFont(name: "AvenirNext-Bold",
                                        size: 24)!
        }
        
        fileprivate struct Color {
            static let blue = UIColor(hex: 0x0099FF)
            static let lightGrey = UIColor(hex: 0xCCCCCC)
            static let grey = UIColor(hex: 0x414141)
            static let border = UIColor(white: 1, alpha: 0.32)
        }
    }
    
    /// Adjust the button's style
    public var style: Style {
        didSet {
            updateStyle()
        }
    }
    
    /// This wraps `style` for use in Storyboards
    /// If adjusting programatically, consider using `style`
    @IBInspectable
    public var isLightStyle: Bool {
        get { return style == .light }
        set {
            if newValue {
                style = .light
            } else {
                style = .dark
            }
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
    
    /// Create a `Connection`'s connect button. This is primarily an internal type. This is the only public method. Use with `ConnectButtonController`.
    ///
    /// - Parameter style: Adjust the buttons background for light and dark backgrounds. Defaults to a light style.
    public init(style: Style = .light) {
        self.style = style
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
    
    
    // MARK: - Button state
    
    struct Service {
        let iconURL: URL?
        let brandColor: UIColor
    }
    
    enum AnimationState {
        case loading(message: String)
        case loadingFailed
        case connect(service: Service, message: String)
        case createAccount(message: String)
        case slideToConnect(message: String)
        case slideToConnectService(service: Service, message: String)
        case slideToDisconnect(message: String)
        case disconnecting(message: String)
        case enterEmail(service: Service, suggestedEmail: String)
        case accessingAccount(message: String)
        case verifyingEmail(message: String)
        case continueToService(service: Service, message: String)
        case connecting(message: String)
        case checkmark
        case connected(service: Service, message: String)
        case disconnected(message: String)
    }
    
    /// Groups button State and footer value into a single state transition
    struct Transition {
        let state: AnimationState?
        let footerValue: LabelValue?
        let duration: TimeInterval
        
        init(state: AnimationState, duration: TimeInterval) {
            self.state = state
            self.footerValue = nil
            self.duration = duration
        }
        init(footerValue: LabelValue, duration: TimeInterval) {
            self.state = nil
            self.footerValue = footerValue
            self.duration = duration
        }
        init(state: AnimationState?, footerValue: LabelValue?, duration: TimeInterval) {
            self.state = state
            self.footerValue = footerValue
            self.duration = duration
        }
        
        static func buttonState(_ state: AnimationState, duration: TimeInterval = 0.5) -> Transition {
            return Transition(state: state, footerValue: nil, duration: duration)
        }
        static func buttonState(_ state: AnimationState, footerValue: LabelValue, duration: TimeInterval = 0.5) -> Transition {
            return Transition(state: state, footerValue: footerValue, duration: duration)
        }
        static func footerValue(_ value: LabelValue, duration: TimeInterval = 0.5) -> Transition {
            return Transition(state: nil, footerValue: value, duration: duration)
        }
    }
    
    func animator(for transition: Transition) -> UIViewPropertyAnimator {
        let animator = UIViewPropertyAnimator(duration: transition.duration,
                                              timingParameters: UISpringTimingParameters(dampingRatio: 1))
        if let state = transition.state {
            // We currently can't support interrupting animations with other touch events
            // Animations must complete before we will respond to the next event
            // Note: This does not effect dragging the toggle since any ongoing touch events will continue
            animator.isUserInteractionEnabled = false
            animation(for: state, with: animator)
        }
        
        if let footerValue = transition.footerValue {
            footerLabelAnimator.transition(with: .crossfade,
                                           updatedValue: footerValue,
                                           addingTo: animator)
        }
        
        return animator
    }
    
    
    // MARK: - Interaction
    
    struct ToggleInteraction {
        // How easy is it to throw the switch into the next position
        enum Resistance {
            case light, heavy
            
            fileprivate func shouldReverse(switchOn: Bool, velocity: CGFloat, progress: CGFloat) -> Bool {
                // Negative velocity is oriented towards switch off
                switch (self, switchOn) {
                case (.light, true):
                    return velocity < -0.1 || (abs(velocity) < 0.05 && progress < 0.4)
                    
                case (.light, false):
                    return velocity > 0.1 || (abs(velocity) < 0.05 && progress > 0.6)
                    
                case (.heavy, true):
                    return progress < 0.5 && velocity > -0.1
                    
                case (.heavy, false):
                    return progress < 0.5 && velocity < 0.1
                }
            }
        }
        
        /// Can the switch be tapped
        var isTapEnabled: Bool
        
        /// Can the switch be dragged
        var isDragEnabled: Bool
        
        var resistance: Resistance
        
        /// What is the next button state when switching the toggle
        var toggleTransition: (() -> Transition)?
        
        /// Callback when switch is toggled
        /// Sends true if switch has been toggled to the on position
        var onToggle: (() -> Void)?
        
        init(isTapEnabled: Bool = false,
             isDragEnabled: Bool = false,
             resistance: Resistance = .light,
             toggleTransition: (() -> Transition)? = nil,
             onToggle: (() -> Void)? = nil) {
            self.isTapEnabled = isTapEnabled
            self.isDragEnabled = isDragEnabled
            self.resistance = resistance
            self.toggleTransition = toggleTransition
            self.onToggle = onToggle
        }
    }
    
    struct EmailInteraction {
        /// Callback when the email address is confirmed
        var onConfirm: ((String) -> Void)?
    }
    
    struct SelectInteraction {
        var isTapEnabled: Bool = false
        
        var onSelect: (() -> Void)?
    }
    
    var toggleInteraction = ToggleInteraction() {
        didSet {
            updateInteraction()
        }
    }
    
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
    
    var stepInteraction = SelectInteraction() {
        didSet {
            updateInteraction()
        }
    }
    
    var footerInteraction = SelectInteraction() {
        didSet {
            updateInteraction()
        }
    }
    
    private lazy var toggleTapGesture = SelectGestureRecognizer(target: self, action: #selector(handleSwitchTap(_:)))
    
    private lazy var toggleDragGesture = UIPanGestureRecognizer(target: self, action: #selector(handleSwitchDrag(_:)))
    
    private lazy var stepSelection = Selectable(backgroundView) { [weak self] in
        self?.stepInteraction.onSelect?()
    }
    
    private lazy var footerSelection = Selectable(footerLabelAnimator.primary.view) { [weak self] in
        self?.footerInteraction.onSelect?()
    }
    
    private var currentToggleAnimation: UIViewPropertyAnimator?
    
    private func getToggleAnimation() -> UIViewPropertyAnimator? {
        if currentToggleAnimation != nil {
            return currentToggleAnimation
        }
        
        guard let transition = toggleInteraction.toggleTransition?() else {
            return nil
        }
        
        let animator = self.animator(for: transition)
        animator.addCompletion { position in
            if position == .end {
                self.toggleInteraction.onToggle?()
            }
        }
        return animator
    }
    
    @objc private func handleSwitchTap(_ gesture: SelectGestureRecognizer) {
        if gesture.state == .ended {
            if let animation = getToggleAnimation() {
                animation.startAnimation()
                currentToggleAnimation = nil
            }
        }
    }
    
    @objc private func handleSwitchDrag(_ gesture: UIPanGestureRecognizer) {
        guard let animation = getToggleAnimation() else {
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
        
        switchControl.addGestureRecognizer(toggleDragGesture)
        toggleDragGesture.delegate = self
        
        emailConfirmButton.onSelect { [weak self] in
            self?.confirmEmail()
        }
        emailEntryField.delegate = self
    }
    
    private func updateInteraction() {
        toggleTapGesture.isEnabled = toggleInteraction.isTapEnabled
        toggleDragGesture.isEnabled = toggleInteraction.isDragEnabled
        stepSelection.isEnabled = stepInteraction.isTapEnabled
        footerSelection.isEnabled = footerInteraction.isTapEnabled
    }
    
    fileprivate func confirmEmail() {
        let _ = emailEntryField.resignFirstResponder()
        emailInteraction.onConfirm?(emailEntryField.text ?? "")
    }
    
    
    // MARK: - UI
    
    private func updateStyle() {
        backgroundColor = .clear
        
        switch style {
        case .light:
            emailConfirmButton.backgroundColor = .black
            emailConfirmButton.imageView.tintColor = .white
            emailConfirmButton.layer.shadowColor = UIColor.clear.cgColor
            
            footerLabelAnimator.primary.label.textColor = .black
            footerLabelAnimator.transition.label.textColor = .black
            
            backgroundView.border = .none
            progressBar.insetForButtonBorder = 0
            
        case .dark:
            emailConfirmButton.backgroundColor = .white
            emailConfirmButton.imageView.tintColor = .black
            // Add a shadow to the left side of the button to delineate it from the email field background
            let layer = emailConfirmButton.layer
            layer.shadowColor = UIColor.black.cgColor
            layer.shadowOpacity = 0.2
            layer.shadowRadius = 5
            layer.shadowOffset = CGSize(width: -2, height: 0)
            
            footerLabelAnimator.primary.label.textColor = .white
            footerLabelAnimator.transition.label.textColor = .white
            
            backgroundView.border = .init(color: Style.Color.border, width: Layout.borderWidth)
            progressBar.insetForButtonBorder = Layout.borderWidth
        }
    }
    
    /// When this button is configured in a Storyboard / NIB, this defines the preview state
    public override func prepareForInterfaceBuilder() {
        backgroundView.backgroundColor = .black
        switchControl.alpha = 1
        switchControl.isOn = false
        switchControl.knob.backgroundColor = Style.Color.blue
        primaryLabelAnimator.configure(.text("Connect"), insets: .avoidSwitchKnob)
        let initialFooterText = NSMutableAttributedString(string: "Powered by IFTTT", attributes: [.font : UIFont.footnote(weight: .bold)])
        footerLabelAnimator.configure(.attributed(initialFooterText))
    }
    
    fileprivate let backgroundView = PillView()
    
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
    fileprivate let emailConfirmButtonTrack = PassthroughView()
    
    fileprivate let emailConfirmButton = PillButton(UIImage())
    
    fileprivate let emailEntryField: UITextField = {
        let field = UITextField(frame: .zero)
        field.keyboardType = .emailAddress
        field.autocapitalizationType = .none
        return field
    }()
    
    // MARK: Text
    
    enum LabelValue: Equatable {
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
        
        static func ==(lhs: LabelValue, rhs: LabelValue) -> Bool {
            switch (lhs, rhs) {
            case (.none, .none):
                return true
            case (.text(let lhs), .text(let rhs)):
                return lhs == rhs
            case (.attributed(let lhs), .attributed(let rhs)):
                return lhs == rhs
            default:
                return false
            }
        }
    }
    
    fileprivate var primaryLabelAnimator = LabelAnimator {
        $0.textAlignment = .center
        $0.textColor = .white
        $0.font = Style.Font.connect
        $0.adjustsFontSizeToFitWidth = true
    }
    
    fileprivate let footerLabelAnimator = LabelAnimator {
        $0.numberOfLines = 1
        $0.textAlignment = .center
        $0.lineBreakMode = .byTruncatingMiddle
    }
    
    fileprivate class LabelAnimator {
        
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
            
            static let zero = Insets(left: 0, right: 0)
            static let standard = Insets(left: 0.5 * Layout.height,
                                         right: 0.5 * Layout.height)
            
            static let avoidServiceIcon = Insets(left: 0.5 * Layout.height + 0.5 * Layout.serviceIconDiameter + 10,
                                                 right: standard.right)
            
            static var avoidSwitchKnob: Insets {
                let avoidSwitch = 0.5 * Layout.height + 0.5 * Layout.knobDiameter + 10
                return Insets(left: avoidSwitch, right: avoidSwitch)
            }
            
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
    
    
    // MARK: Progress bar
    
    fileprivate let progressBar = ProgressBar()
    
    fileprivate class ProgressBar: PassthroughView {
        var fractionComplete: CGFloat = 0 {
            didSet {
                update()
            }
        }
        
        /// When using a border with the ConnectButton, set this to the border width
        /// This will inset the progress bar so it doesn't overlap the border
        /// When a border isn't used, set this to 0
        var insetForButtonBorder: CGFloat = 0 {
            didSet {
                layoutMargins = UIEdgeInsets(top: insetForButtonBorder,
                                             left: insetForButtonBorder,
                                             bottom: insetForButtonBorder,
                                             right: insetForButtonBorder)
            }
        }
        
        private let track = UIView()
        private let bar = PassthroughView()
        
        func configure(with service: Service?) {
            bar.backgroundColor = service?.brandColor.contrasting() ?? Style.Color.grey
        }
        
        private func update() {
            bar.transform = CGAffineTransform(translationX: (1 - fractionComplete) * -bounds.width, y: 0)
            track.layer.cornerRadius = 0.5 * bounds.height // Progress bar should match rounded corners of connect button
        }
        
        override func layoutSubviews() {
            super.layoutSubviews()
            update()
        }
        
        init() {
            super.init(frame: .zero)
            
            // The track ensures that the progress bar stays within its intended bounds
            
            track.clipsToBounds = true
            
            addSubview(track)
            track.constrain.edges(to: layoutMarginsGuide)
            
            track.addSubview(bar)
            bar.constrain.edges(to: track)
            
            layoutMargins = .zero
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
                
                layer.shadowColor = UIColor.black.cgColor
                layer.shadowOpacity = 0.25
                layer.shadowRadius = 2
                layer.shadowOffset = CGSize(width: 2, height: 8)
                
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
        
        func configure(with service: Service, networkController: ImageViewNetworkController?) {
            networkController?.setImage(with: service.iconURL, for: knob.iconView)
            
            let color = service.brandColor
            knob.backgroundColor = color
            
            // If the knob color is too close to black, draw a border around it
            if color.distance(from: .black, comparing: .monochrome) < 0.2 {
                knob.border = .init(color: Style.Color.border, width: Layout.borderWidth)
            } else {
                knob.border = .none
            }
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
            outline.layer.borderColor = Style.Color.border.cgColor
            
            outline.constrain.center(in: self)
            outline.constrain.square(length: Layout.checkmarkDiameter)
            
            addSubview(indicator)
            indicator.translatesAutoresizingMaskIntoConstraints = false
            indicator.frame = CGRect(x: 0, y: 0, width: lineWidth, height: lineWidth)
            
            layer.addSublayer(checkmarkShape)
            
            indicator.backgroundColor = .white
            checkmarkShape.fillColor = UIColor.clear.cgColor
            checkmarkShape.strokeColor = UIColor.white.cgColor
            #if swift(>=4.2)
            checkmarkShape.lineCap = .round
            checkmarkShape.lineJoin = .round
            #else
            checkmarkShape.lineCap = kCALineCapRound
            checkmarkShape.lineJoin = kCALineJoinRound
            #endif
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
        
        emailEntryField.constrain.edges(to: backgroundView,
                                        inset: UIEdgeInsets(top: 0, left: LabelAnimator.Insets.standard.left,
                                                            bottom: 0, right: LabelAnimator.Insets.avoidSwitchKnob.right))
        
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

@available(iOS 10.0, *)
extension ConnectButton: UIGestureRecognizerDelegate {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        // Prevents the tap gesture from interfering with scrolling when it is placed in a scroll view
        // We don't want this behavior for the toggle drag gesture. The scroll view should not move when the user is dragging the toggle.
        return self.toggleTapGesture == gestureRecognizer
    }
}

// MARK: Text field delegate (email)

@available(iOS 10.0, *)
extension ConnectButton: UITextFieldDelegate {
    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        confirmEmail()
        return true
    }
}


// MARK: - Animation

// MARK: Checkmark

@available(iOS 10.0, *)
private extension ConnectButton.CheckmarkView {
    func drawCheckmark(duration: TimeInterval) {
        UIView.performWithoutAnimation {
            self.indicator.alpha = 1
        }
        reset()
        
        let indicatorAnimation = CAKeyframeAnimation(keyPath: "position")
        indicatorAnimation.path = indicatorAnimationPath.cgPath
        indicatorAnimation.duration = 0.6 * duration
        #if swift(>=4.2)
        indicatorAnimation.timingFunction = CAMediaTimingFunction(name: .easeIn)
        #else
        indicatorAnimation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseIn)
        #endif
        indicatorAnimation.delegate = self
        indicator.layer.add(indicatorAnimation, forKey: "position along path")
        indicator.layer.position = indicatorAnimationPath.currentPoint
    }
}

@available(iOS 10.0, *)
extension ConnectButton.CheckmarkView: CAAnimationDelegate {
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        if anim is CAKeyframeAnimation {
            indicator.alpha = 0
            
            checkmarkShape.strokeEnd = 1
            let checkmarkAnimation = CABasicAnimation(keyPath: "strokeEnd")
            checkmarkAnimation.fromValue = 0
            checkmarkAnimation.toValue = 1
            checkmarkAnimation.duration = 0.4 * anim.duration
            #if swift(>=4.2)
            checkmarkAnimation.timingFunction = CAMediaTimingFunction(name: .easeOut)
            #else
            checkmarkAnimation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
            #endif
            self.checkmarkShape.add(checkmarkAnimation, forKey: "draw line")
        }
    }
}

// MARK: Progress bar

@available(iOS 10.0, *)
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

@available(iOS 10.0, *)
private extension ConnectButton {
    
    func animation(for animationState: AnimationState, with animator: UIViewPropertyAnimator) {
        switch animationState {
        case let .loading(message):
            transitionToLoading(message: message, animator: animator)
            
        case .loadingFailed:
            transitionToLoadingFailed()
            
        case let .connect(service, message):
            transitionToConnect(service: service, message: message, animator: animator)
            
        case let .createAccount(message):
            primaryLabelAnimator.transition(with: .crossfade, updatedValue: .text(message), insets: .standard, addingTo: animator)
            
        case let .slideToDisconnect(message):
            transitionToSlideToDisconnect(message: message, animator: animator)
            
        case let .disconnecting(message):
            transitionToDisconnecting(message: message, animator: animator)
            
        case let .slideToConnect(message):
            transitionToSlideToConnect(isOn: true,
                                       service: nil,
                                       labelValue: .text(message),
                                       animator: animator)

        case let .slideToConnectService(service, message):
            transitionToSlideToConnect(isOn: true,
                                       service: service,
                                       labelValue: .text(message),
                                       animator: animator)
            
        case let .enterEmail(service, suggestedEmail):
            transitionToEmail(service: service, suggestedEmail: suggestedEmail, animator: animator)
            
        case let .accessingAccount(message):
            transitionToAccessingAccount(message: message, animator: animator)
        
        case let .verifyingEmail(message):
            transitionToVerifyingAccount(message: message, animator: animator)
            
        case let .continueToService(service, message):
            transitionToContinueToService(service: service, message: message, animator: animator)
            
        case let .connecting(message):
            transitionToConnecting(message: message, animator: animator)
            
        case .checkmark:
            transitionToCheckmark(animator: animator)
            
        case let .connected(service, message):
            transitionToConnected(service: service, message: message, animator: animator)
            
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
    }
    
    private func transitionToConnect(service: Service, message: String, animator: UIViewPropertyAnimator) {
        stopPulseAnimation()
       
        primaryLabelAnimator.transition(with: .crossfade, updatedValue: .text(message), insets: .avoidSwitchKnob, addingTo: animator)
        switchControl.configure(with: service, networkController: self.imageViewNetworkController)
        
        animator.addAnimations {
            self.progressBar.alpha = 0
            self.backgroundView.backgroundColor = .black
            self.switchControl.isOn = false
            self.switchControl.knob.alpha = 1
            self.switchControl.knob.maskedEndCaps = .all
            self.switchControl.knob.iconView.alpha = 1
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
        
        primaryLabelAnimator.transition(with: .crossfade,
                                        updatedValue: labelValue,
                                        insets: .avoidSwitchKnob,
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
        
        emailEntryField.text = email
        
        emailConfirmButton.transform = CGAffineTransform(scaleX: 1 / scaleFactor, y: 1 / scaleFactor)
        emailConfirmButton.maskedEndCaps = .all // Match the switch knob at the start of the animation
        
        primaryLabelAnimator.transition(with: .crossfade,
                                        updatedValue: .none,
                                        addingTo: animator)
        
        progressBar.configure(with: nil)
        progressBar.alpha = 0
        
        emailEntryField.alpha = 0
        animator.addAnimations {
            self.backgroundView.backgroundColor = Style.Color.lightGrey
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
            
            switch self.style {
            case .dark:
                self.switchControl.knob.backgroundColor = .white
            case .light:
                self.switchControl.knob.backgroundColor = .black
            }
        }, delayFactor: 0.25)
        
        animator.addAnimations({
            self.emailConfirmButton.alpha = 1
            self.emailEntryField.alpha = 1
        }, delayFactor: 0.7)
        
        animator.addCompletion { position in
            
            switch position {
            case .start:
                // Keep the knob is a "clean" state since we don't animate backwards from this step
                self.switchControl.knob.transform = .identity
                self.switchControl.knob.maskedEndCaps = .all // reset
                self.switchControl.knob.layer.shadowOpacity = 0.25
                self.switchControl.configure(with: service, networkController: self.imageViewNetworkController)
                self.switchControl.knob.iconView.alpha = 1.0
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
                }
                
                endAnimator.startAnimation()
                
            default:
                break
            }
        }
    }
    
    private func transitionToAccessingAccount(message: String, animator: UIViewPropertyAnimator) {
        primaryLabelAnimator.transition(with: .crossfade, updatedValue: .text(message), insets: .standard, addingTo: animator)
        
        progressBar.configure(with: nil)
        progressBar.alpha = 1
        
        animator.addAnimations {
            self.switchControl.alpha = 0
        }
    }
    
    private func transitionToVerifyingAccount(message: String, animator: UIViewPropertyAnimator) {
        primaryLabelAnimator.transition(with: .crossfade, updatedValue: .text(message), insets: .standard, addingTo: animator)
        
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
        primaryLabelAnimator.transition(with: .crossfade, updatedValue: .text(message), insets: .standard, addingTo: animator)
        
        progressBar.configure(with: service)
        
        animator.addAnimations {
            self.backgroundView.backgroundColor = service.brandColor
        }
    }
    
    private func transitionToCheckmark(animator: UIViewPropertyAnimator) {
        primaryLabelAnimator.transition(with: .crossfade, updatedValue: .none, addingTo: animator)
        
        backgroundView.backgroundColor = .black
        
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
    
    private func transitionToConnecting(message: String, animator: UIViewPropertyAnimator) {
        primaryLabelAnimator.transition(with: .crossfade, updatedValue: .text(message), insets: .standard, addingTo: animator)
    
        backgroundView.backgroundColor = .black
        switchControl.knob.iconView.alpha = 1
        switchControl.knob.transform = .identity
        switchControl.knob.maskedEndCaps = .all
 
        progressBar.configure(with: nil)
        progressBar.alpha = 1
        
        // We don't show messages and the switch at the same time
        switchControl.alpha = 0
    }
    
    private func transitionToConnected(service: Service, message: String, animator: UIViewPropertyAnimator) {
        stopPulseAnimation() // If we canceled disconnect
        
        switchControl.primeAnimation_centerKnob()
        primaryLabelAnimator.transition(with: .crossfade, updatedValue: .text(message), insets: .avoidSwitchKnob, addingTo: animator)
        
        progressBar.configure(with: service)
        progressBar.fractionComplete = 0
        
        animator.addAnimations {
            self.backgroundView.backgroundColor = .black
            
            self.switchControl.configure(with: service, networkController: self.imageViewNetworkController)
            self.switchControl.alpha = 1
            self.switchControl.knob.alpha = 1
            self.switchControl.knob.iconView.alpha = 1
            self.switchControl.isOn = true
            
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
        primaryLabelAnimator.transition(with: .crossfade,
                                        updatedValue: .text(message),
                                        insets: .avoidSwitchKnob,
                                        addingTo: animator)
        pulseAnimateLabel(toAlpha: .partial)
    }
    
    private func transitionToDisconnecting(message: String, animator: UIViewPropertyAnimator) {
        primaryLabelAnimator.transition(with: .crossfade,
                                        updatedValue: .text(message),
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
        
        animator.addCompletion { position in
            switch position {
            case .start:
                self.switchControl.isOn = false
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
        primaryLabelAnimator.transition(with: .crossfade,
                                        updatedValue: .text(message),
                                        insets: .standard,
                                        addingTo: animator)
    }
}
