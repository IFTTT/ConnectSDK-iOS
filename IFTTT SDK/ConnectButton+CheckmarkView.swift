//
//  ConnectButton+CheckmarkView.swift
//  IFTTT SDK
//
//  Copyright © 2019 IFTTT. All rights reserved.
//

import Foundation

@available(iOS 10.0, *)
extension ConnectButton {
    
    /// A `UIView` subclass that is used to draw a checkmark when completing activation.
    final class CheckmarkView: UIView {
        
        /// The `UIView` that represents the circular outline of the `CheckmarkView`.
        let outline = UIView()
        private let indicator = UIView()
        private let checkmarkShape = CAShapeLayer()
        
        private let indicatorAnimationPath = UIBezierPath()
        
        private func reset() {
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            checkmarkShape.strokeEnd = 0
            CATransaction.commit()
        }
        
        /// Creates a `CheckmarkView`.
        init() {
            super.init(frame: .zero)
            
            constrain.square(length: Layout.height)
            
            let lineWidth: CGFloat = 3
            
            addSubview(outline)
            outline.layer.borderWidth = lineWidth
            outline.layer.borderColor = Color.border.cgColor
            
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
}

@available(iOS 10.0, *)
extension ConnectButton.CheckmarkView {
    
    /// Draws the checkmark.
    ///
    /// - Parameter duration: The amount of time the checkmark should be drawn in.
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
