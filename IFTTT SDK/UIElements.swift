//
//  UIElements.swift
//  IFTTT SDK
//
//  Created by Jon Chmura on 9/17/18.
//  Copyright © 2018 IFTTT. All rights reserved.
//

import UIKit

// MARK: - Autolayout

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

extension UIStackView {
    convenience init(_ views: [UIView], _ configure: ((UIStackView) -> Void)?) {
        self.init(arrangedSubviews: views)
        configure?(self)
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
