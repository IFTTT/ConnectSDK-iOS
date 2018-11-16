//
//  UIElements.swift
//  IFTTT SDK
//
//  Created by Jon Chmura on 9/17/18.
//  Copyright © 2018 IFTTT. All rights reserved.
//

import UIKit

// MARK: - Autolayout

@available(iOS 10.0, *)
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
        func square() {
            view.widthAnchor.constraint(equalTo: view.heightAnchor).isActive = true
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
                view.bottomAnchor.constraint(equalTo: otherView.bottomAnchor, constant: -inset.bottom).isActive = true
            }
            if edges.contains(.right) {
                view.rightAnchor.constraint(equalTo: otherView.rightAnchor, constant: -inset.right).isActive = true
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


// MARK: - Convenience

extension UILabel {
    convenience init(_ text: String, _ configure: ((UILabel) -> Void)?) {
        self.init()
        self.text = text
        configure?(self)
    }
    convenience init(_ attributedText: NSAttributedString, _ configure: ((UILabel) -> Void)?) {
        self.init()
        self.attributedText = attributedText
        configure?(self)
    }
}

@available(iOS 10.0, *)
extension UIStackView {
    convenience init(_ views: [UIView], _ configure: ((UIStackView) -> Void)?) {
        self.init(arrangedSubviews: views)
        configure?(self)
    }
}


// MARK: - Pill view

/// A UI view with circular endcaps
/// Each end cap may be configured individually to be square or rounded
@available(iOS 10.0, *)
class PillView: UIView {
    
    /// A mask for revealing the left and right end caps
    /// Non-revealed end caps are square
    struct EndCapMask: OptionSet {
        let rawValue: Int
        
        /// Reveal the left end cap
        static let left = EndCapMask(rawValue: 1 << 0)
        /// Reveal the right end cap
        static let right = EndCapMask(rawValue: 1 << 1)
        
        /// Reveal both endcaps
        static let all: EndCapMask = [.left, .right]
        /// Reveal neither endcap (both sides are square)
        static let none: EndCapMask = []
    }
    
    /// Set the end cap mask
    /// Non-masked end caps are square
    /// Animatable
    var maskedEndCaps: EndCapMask = .all {
        didSet {
            [leftCapView, leftBorder].forEach {
                $0.curvature = maskedEndCaps.contains(.left) ? 1 : 0
            }
            [rightCapView, rightBorder].forEach {
                $0.curvature = maskedEndCaps.contains(.right) ? 1 : 0
            }
        }
    }
    
    /// Describes the border around the view
    struct Border {
        let color: UIColor
        let width: CGFloat
        var opacity: CGFloat
        
        init(color: UIColor, width: CGFloat, opacity: CGFloat = 1) {
            self.color = color
            self.width = width
            self.opacity = opacity
        }
        static let none = Border(color: .clear, width: 0, opacity: 0)
    }
    
    /// Configure the view's border
    /// Use this instead of `layer.borderColor` & `layer.borderWidth`
    var border: Border = .none {
        didSet {
            topBorderHeight.constant = border.width
            bottomBorderHeight.constant = border.width
            
            [topBorder, bottomBorder].forEach {
                $0.backgroundColor = border.color
                $0.alpha = border.opacity
            }
            [leftBorder, rightBorder].forEach {
                $0.layer.borderColor = border.color.cgColor
                $0.layer.borderWidth = border.width
                $0.alpha = border.opacity
            }
        }
    }
    
    /// A half circle view for drawing the end caps
    private class EndCapView: UIView {
        
        /*
         In `ConnectButton`, when a user turns on a Connection for the first time, the switch knob morphs from a circle to a bullet shape
         (One side is flat and the other is rounded)
         
         This animation may happen interactively when the user drags the switch
         
         Unfortunately, We can't simply use `layer.maskedCorners` or draw the endcaps using a mask backed by a `CAShapeLayer` since neither `layer.maskedCorners` or `shapeLayer.path` can take part in `UIView` animations
         
         Our solution is to draw each end cap separately
         The end cap will round all of its corners but we mask the opposite side, creating a half circle
         */
        
        var curvature: CGFloat = 1 {
            didSet {
                updateCornerRadius()
            }
        }
        
        private let isLeftSide: Bool
        
        init(isLeftSide: Bool) {
            self.isLeftSide = isLeftSide
            super.init(frame: .zero)
            
            mask = UIView()
            mask?.backgroundColor = .white
        }
        @available(*, unavailable)
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        private func updateCornerRadius() {
            layer.cornerRadius = curvature * 0.5 * bounds.height
        }
        
        override func layoutSubviews() {
            super.layoutSubviews()
            updateCornerRadius()
            
            if isLeftSide {
                mask?.frame = CGRect(x: 0, y: 0, width: 0.5 * bounds.width, height: bounds.height)
            } else {
                mask?.frame = CGRect(x: 0.5 * bounds.width, y: 0, width: 0.5 * bounds.width, height: bounds.height)
            }
        }
    }
    
    private let leftCapView = EndCapView(isLeftSide: true)
    private let rightCapView = EndCapView(isLeftSide: false)
    private let centerView = UIView()
    
    /*
     The view's border is tricky due to how we draw the end caps
     We can't simply apply a border to the whole view since it wouldn't follow the actual end caps
     Instead, we draw each segment of the border using a `UIView`
     */
    
    private let topBorder = UIView()
    private lazy var topBorderHeight: NSLayoutConstraint = {
        return topBorder.heightAnchor.constraint(equalToConstant: 0)
    }()
    private let leftBorder = EndCapView(isLeftSide: true)
    private let rightBorder = EndCapView(isLeftSide: false)
    private let bottomBorder = UIView()
    private lazy var bottomBorderHeight: NSLayoutConstraint = {
        return bottomBorder.heightAnchor.constraint(equalToConstant: 0)
    }()
    
    override var backgroundColor: UIColor? {
        get {
            return centerView.backgroundColor
        }
        set {
            [leftCapView, centerView, rightCapView].forEach {
                $0.backgroundColor = newValue
            }
        }
    }
    
    init() {
        super.init(frame: .zero)
        
        addSubview(leftCapView)
        addSubview(centerView)
        addSubview(rightCapView)
        
        leftCapView.constrain.edges(to: self, edges: [.top, .left, .bottom])
        leftCapView.centerXAnchor.constraint(equalTo: centerView.leftAnchor).isActive = true
        centerView.constrain.edges(to: self, edges: [.top, .bottom])
        centerView.rightAnchor.constraint(equalTo: rightCapView.centerXAnchor).isActive = true
        rightCapView.constrain.edges(to: self, edges: [.top, .right, .bottom])
        
        leftCapView.constrain.square()
        rightCapView.constrain.square()
        
        addSubview(topBorder)
        addSubview(leftBorder)
        addSubview(rightBorder)
        addSubview(bottomBorder)
        
        topBorder.constrain.edges(to: centerView, edges: [.left, .top, .right])
        topBorderHeight.isActive = true
        
        leftBorder.constrain.edges(to: leftCapView)
        rightBorder.constrain.edges(to: rightCapView)
        
        bottomBorder.constrain.edges(to: centerView, edges: [.left, .bottom, .right])
        bottomBorderHeight.isActive = true
    }
    
    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}


// MARK: - Pill button

@available(iOS 10.0, *)
class PillButton: PillView {
    
    let label = UILabel()
    
    let imageView = UIImageView()
    
    func onSelect(_ body: @escaping (() -> Void)) {
        assert(selectable == nil, "PillButton may have a single select handler")
        selectable = Selectable(self, onSelect: body)
    }
    
    private var selectable: Selectable?
    
    override var intrinsicContentSize: CGSize {
        if imageView.image != nil {
            var size = imageView.intrinsicContentSize
            size.height += 20
            size.width += 20
            return size
        } else {
            return super.intrinsicContentSize
        }
    }
    
    init(_ image: UIImage, _ configure: ((PillButton) -> Void)? = nil) {
        super.init()
        
        addSubview(imageView)
        imageView.constrain.center(in: self)
        
        imageView.image = image
        
        configure?(self)
    }
    
    init(_ text: String, _ configure: ((PillButton) -> Void)? = nil) {
        super.init()
        
        label.text = text
        label.textAlignment = .center
        
        layoutMargins = UIEdgeInsets(top: 12, left: 32, bottom: 12, right: 32)
        addSubview(label)
        label.constrain.edges(to: layoutMarginsGuide)
        
        configure?(self)
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

@available(iOS 10.0, *)
class Selectable: NSObject, UIGestureRecognizerDelegate {
    var isEnabled: Bool {
        get { return gesture.isEnabled }
        set { gesture.isEnabled = newValue }
    }
    
    private let gesture = SelectGestureRecognizer()
    private var onSelect: () -> Void
    
    init(_ view: UIView, onSelect: @escaping () -> Void) {
        self.onSelect = onSelect
        
        super.init()
        
        gesture.addTarget(self, action: #selector(handleSelect(_:)))
        gesture.delaysTouchesBegan = true
        gesture.delegate = self
        
        view.addGestureRecognizer(gesture)
    }
    
    @objc private func handleSelect(_ gesture: UIGestureRecognizer) {
        if gesture.state == .ended {
            onSelect()
        }
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}

@available(iOS 10.0, *)
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
