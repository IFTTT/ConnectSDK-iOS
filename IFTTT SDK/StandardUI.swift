//
//  StandardUI.swift
//  IFTTT SDK
//
//  Created by Jon Chmura on 9/17/18.
//  Copyright © 2018 IFTTT. All rights reserved.
//

import UIKit

extension UIView {
    var constrain: Constraints {
        return Constraints(view: self)
    }
    
    struct Constraints {
        fileprivate let view: UIView
        
        fileprivate init(view: UIView) {
            self.view = view
            view.translatesAutoresizingMaskIntoConstraints = false
        }
        
        func center(in otherView: UIView) {
            view.centerXAnchor.constraint(equalTo: otherView.centerXAnchor).isActive = true
            view.centerYAnchor.constraint(equalTo: otherView.centerYAnchor).isActive = true
        }
        func square(length: CGFloat) {
            view.heightAnchor.constraint(equalToConstant: length).isActive = true
            view.widthAnchor.constraint(equalToConstant: length).isActive = true
        }
        func width(to otherView: UIView) {
            view.widthAnchor.constraint(equalTo: otherView.widthAnchor).isActive = true
        }
        func edges(to otherView: UIView, edges: UIRectEdge = .all, inset: UIEdgeInsets = .zero) {
            if edges.contains(.top) {
                view.topAnchor.constraint(equalTo: otherView.topAnchor, constant: inset.top).isActive = true
            }
            if edges.contains(.left) {
                view.leftAnchor.constraint(equalTo: otherView.leftAnchor, constant: inset.left).isActive = true
            }
            if edges.contains(.bottom) {
                view.bottomAnchor.constraint(equalTo: otherView.bottomAnchor, constant: inset.bottom).isActive = true
            }
            if edges.contains(.right) {
                view.rightAnchor.constraint(equalTo: otherView.rightAnchor, constant: inset.right).isActive = true
            }
        }
        func edges(to guide: UILayoutGuide, edges: UIRectEdge = .all) {
            if edges.contains(.top) {
                view.topAnchor.constraint(equalTo: guide.topAnchor).isActive = true
            }
            if edges.contains(.left) {
                view.leftAnchor.constraint(equalTo: guide.leftAnchor).isActive = true
            }
            if edges.contains(.bottom) {
                view.bottomAnchor.constraint(equalTo: guide.bottomAnchor).isActive = true
            }
            if edges.contains(.right) {
                view.rightAnchor.constraint(equalTo: guide.rightAnchor).isActive = true
            }
        }
    }
}


extension UIEdgeInsets {
    init(inset: CGFloat) {
        self.init(top: inset, left: inset, bottom: inset, right: inset)
    }
}


// MARK - Label

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
    
    func setupLabels(_ body: (UILabel) -> Void) {
        [primaryView, transitionView].forEach(body)
    }
    
    func configure(_ value: Value) {
        value.update(label: primaryView)
        transitionView.text = nil
    }
    
    func transition(with effect: Effect, updatedText: Value, addingTo externalAnimator: UIViewPropertyAnimator? = nil) {
        switch effect {
        case .crossfade:
            // FIXME: This really isn't quite right
            // Probably won't work as expected for toggling switch
            // We need an animation where the text reveals / hides from left to right
            let animator = externalAnimator ?? UIViewPropertyAnimator(duration: 0.3, curve: .easeOut, animations: nil)
            if updatedText.isEmpty {
                animator.addAnimations {
                    self.primaryView.alpha = 0
                }
            } else {
                updatedText.update(label: primaryView)
                primaryView.alpha = 0
                animator.addAnimations {
                    self.primaryView.alpha = 1
                }
            }
            if externalAnimator == nil {
                animator.startAnimation()
            }
            
        case .slideInFromRight:
            updatedText.update(label: primaryView)
            primaryView.alpha = 0
            primaryView.transform = CGAffineTransform(translationX: 20, y: 0)
            
            let animator = externalAnimator ?? UIViewPropertyAnimator(duration: 0.3, curve: .easeOut, animations: nil)
            animator.addAnimations {
                self.primaryView.transform = .identity
                self.primaryView.alpha = 1
            }
            if externalAnimator == nil {
                animator.startAnimation()
            }
            
        case .rotateDown:
            assert(externalAnimator == nil, "Not supported for rotate transitions")
            
            updatedText.update(label: transitionView)
            
            transitionView.alpha = 0
            transitionView.transform = CGAffineTransform(translationX: 0, y: -20).scaledBy(x: 0.9, y: 0.9)
            
            let animator = UIViewPropertyAnimator(duration: 0.2, curve: .easeIn, animations: nil)
            animator.addAnimations {
                self.primaryView.alpha = 0
                self.primaryView.transform = CGAffineTransform(translationX: 0, y: 20).scaledBy(x: 0.9, y: 0.9)
            }
            animator.addCompletion { _ in
                let nextAnimator = UIViewPropertyAnimator(duration: 0.2, curve: .easeOut) {
                    self.transitionView.alpha = 1
                    self.transitionView.transform = .identity
                }
                nextAnimator.addCompletion { _ in
                    self.transitionView.text = nil
                    updatedText.update(label: self.primaryView)
                    self.primaryView.alpha = 1
                    self.primaryView.transform = .identity
                }
                nextAnimator.startAnimation()
            }
            animator.startAnimation()
        }
    }
    
    /// Diplays the content of this label
    let primaryView = UILabel()
    
    /// Used in text transition effects
    let transitionView = UILabel()
    
    init() {
        super.init(frame: .zero)
        
        layoutMargins = .zero
        
        [primaryView, transitionView].forEach { (label) in
            addSubview(label)
            label.constrain.center(in: self)
            label.constrain.edges(to: layoutMarginsGuide, edges: [.left, .right])
        }
    }
    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}


// MARK: - Pill view

class PillView: UIView {
    
    var curvature: CGFloat = 1 {
        didSet {
            update()
        }
    }
    
    init() {
        super.init(frame: .zero)
    }
    
    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func update() {
        layer.cornerRadius = 0.5 * curvature * bounds.height
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        update()
    }
}


// MARK: - Pill button

class PillButton: PillView {
    
    var onSelect: (() -> Void)?
    
    init(image: UIImage, tintColor: UIColor, backgroundColor: UIColor) {
        label = UILabel()
        super.init()
        
        self.tintColor = tintColor
        self.backgroundColor = backgroundColor
        
        addSubview(imageView)
        imageView.constrain.center(in: self)
        
        setupSelectGesture()
    }
    
    init(text: String, tintColor: UIColor, backgroundColor: UIColor) {
        label = UILabel(text,
                        style: .callout,
                        alignment: .center)
        
        super.init()
        
        self.tintColor = tintColor
        self.backgroundColor = backgroundColor
        
        layoutMargins = UIEdgeInsets(inset: 10)
        addSubview(label)
        label.constrain.edges(to: layoutMarginsGuide)
        
        setupSelectGesture()
        update()
    }
    
    private let label: UILabel
    
    private let imageView = UIImageView()
    
    private func update() {
        label.textColor = tintColor
    }
    
    private lazy var selectGesture = SelectGestureRecognizer(target: self, action: #selector(handleSelect(_:)))
    
    private func setupSelectGesture() {
        addGestureRecognizer(selectGesture)
        selectGesture.delaysTouchesBegan = true
        selectGesture.delegate = self
    }
    
    @objc private func handleSelect(_ gesture: UIGestureRecognizer) {
        if gesture.state == .ended {
            onSelect?()
        }
    }
}

extension PillButton: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}


// MARK: - Passthrough view

class PassthroughView: UIView {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let view = super.hitTest(point, with: event)
        return view == self ? nil : view
    }
}


// MARK: - SelectGestureRecognizer

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

