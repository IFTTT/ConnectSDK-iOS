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
    
    /// A `UIView` subclass composed of a knob and track that represents the switch of the connect button.
    final class SwitchControl: UIView {
        
        /// A `PillView` subclass that adds an icon image view to represent the circular switch of the connect button.
        final class Knob: PillView {
            
            /// A `UIImageView` to display an icon on the knob.
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
        
        /// Whether the connect button's switch is on or not.
        var isOn: Bool = false {
            didSet {
                centerKnobConstraint.isActive = false
                offConstraint.isActive = !isOn
                track.layoutIfNeeded()
            }
        }
        
        /// Configures the knob with the service coloring and fetches the service's associated icon.
        ///
        /// - Parameters:
        ///   - service: The `Service` model to used to configure the styling of the knob.
        ///   - networkController: An optional `ImageViewNetworkController` for fetching the service's icon.
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
        
        /// The connect button's circular switch.
        let knob = Knob()
        
        private let track = PassthroughView()
        
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
        
        /// Creates a `SwitchControl`.
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
