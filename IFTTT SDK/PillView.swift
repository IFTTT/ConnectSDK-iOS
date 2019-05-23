//
//  PillView.swift
//  IFTTT SDK
//
//  Created by Jon Chmura on 11/26/18.
//  Copyright © 2018 IFTTT. All rights reserved.
//

import UIKit

/// A UI view with circular endcaps
/// Each end cap may be configured individually to be square or rounded
@available(iOS 10.0, *)
class PillView: UIView {
    
    init() {
        super.init(frame: .zero)
        createLayout()
    }
    
    private var _backgroundColor: UIColor?
    
    override var backgroundColor: UIColor? {
        get {
            return _backgroundColor
        }
        set {
            _backgroundColor = newValue
            if isHighlighted == false {
                applyBackgroundColor(newValue)
            }
        }
    }
    
    /// Set the highlighted state for this view
    /// When highlighted the backgroundColor's constrast color is used
    var isHighlighted: Bool = false {
        didSet {
            if isHighlighted {
                applyBackgroundColor(_backgroundColor?.contrasting(brighteningAdjustment: 0.3))
            } else {
                applyBackgroundColor(_backgroundColor)
            }
        }
    }
    
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
    
    private func applyBackgroundColor(_ color: UIColor?) {
        [leftCapView, centerView, rightCapView].forEach {
            $0.backgroundColor = color
        }
    }
    
    private func createLayout() {
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
        
        // In order to make sure the border always draws completely over the view it is pinned to, we need to offset the border to be slightly bigger then the pinned view.
        let topBottomBorderInset = UIEdgeInsets(top: -ConnectButton.Layout.borderWidth, left: 0, bottom: -ConnectButton.Layout.borderWidth, right: 0)
        
        topBorder.constrain.edges(to: centerView, edges: [.left, .top, .right], inset: topBottomBorderInset)
        topBorderHeight.isActive = true
        
        bottomBorder.constrain.edges(to: centerView, edges: [.left, .bottom, .right], inset:topBottomBorderInset)
        bottomBorderHeight.isActive = true
        
        // In order to make sure the border always draws completely over the view it is pinned to, we need to offset the border to be slightly bigger then the pinned view.
        let leftRightBorderInset = UIEdgeInsets(top: -ConnectButton.Layout.borderWidth, left: -ConnectButton.Layout.borderWidth, bottom: -ConnectButton.Layout.borderWidth, right: -ConnectButton.Layout.borderWidth)
        
        leftBorder.constrain.edges(to: leftCapView, inset: leftRightBorderInset)
        rightBorder.constrain.edges(to: rightCapView, inset: leftRightBorderInset)
        
    }
    
    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

@available(iOS 10.0, *)
private extension PillView {
    
    /// A half circle view for drawing the end caps
    final class EndCapView: UIView {
        
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
}
