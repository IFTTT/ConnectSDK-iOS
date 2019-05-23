//
//  ConnectButton+SwitchControl.swift
//  IFTTT SDK
//
//  Created by Michael Amundsen on 5/23/19.
//  Copyright © 2019 IFTTT. All rights reserved.
//

import Foundation

@available(iOS 10.0, *)
extension ConnectButton {
    
    class SwitchControl: UIView {
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
                knob.border = .init(color: Color.border, width: Layout.borderWidth)
            } else {
                knob.border = .none
            }
        }
        
        let knob = Knob()
        let track = PassthroughView()
        
        /// Used to prime particular button animations where the know should start in the center
        func primeAnimation_centerKnob() {
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
}
