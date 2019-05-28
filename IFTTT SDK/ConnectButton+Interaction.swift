//
//  ConnectButton+Interaction.swift
//  IFTTT SDK
//
//  Created by Michael Amundsen on 5/23/19.
//  Copyright © 2019 IFTTT. All rights reserved.
//

import Foundation

@available(iOS 10.0, *)
extension ConnectButton {
    
    /// A structure to wrap various properties associated with the ability to tap or drag the connect button on and off.
    struct ToggleInteraction {
        
        /// An enum to represent how easy is it to throw the switch into the next position.
        enum Resistance {
            
            /// A light amount of resistance to flip the switch.
            case light
            
            /// A heavy amount of resistance to flip the switch.
            case heavy
            
            /// Determines if the switch should reverse based on its resistance.
            ///
            /// - Parameters:
            ///   - switchOn: Whether the switch is moving towards being on.
            ///   - velocity: The value the represents the velocity of the movement towards being on or off.
            ///   - progress: THe value of how far along the button is to being on or off.
            /// - Returns: Whether the toggle interaction should be reversed.
            func shouldReverse(switchOn: Bool, velocity: CGFloat, progress: CGFloat) -> Bool {
                // Negative velocity is oriented towards switch off
                switch (self, switchOn) {
                case (.light, true):
                    return velocity < -0.1 || (abs(velocity) < 0.05 && progress < 0.4)
                    
                case (.light, false):
                    return velocity > 0.1 || (abs(velocity) < 0.05 && progress > 0.6)
                    
                case (.heavy, true):
                    return progress < 0.5
                    
                case (.heavy, false):
                    return progress < 0.5
                }
            }
        }
        
        /// Whether the switch can be tapped.
        var isTapEnabled: Bool
        
        /// Whether the switch can be dragged.
        var isDragEnabled: Bool
        
        /// How easy is it to throw the switch into the next position.
        var resistance: Resistance
        
        /// An optional next button state when toggling the connect button's switch.
        var toggleTransition: (() -> Transition)?
        
        /// An optional callback when the switch is flipped.
        var onToggle: (() -> Void)?
        
        /// An optional callback when the switch is flipped but we reversed the animation to end in the start position.
        var onReverse: (() -> Void)?
        
        /// Creates a `ToggleInteraction`.
        ///
        /// - Parameters:
        ///   - isTapEnabled: Whether the switch can be tapped. Defaults to false.
        ///   - isDragEnabled: Whether the switch can be dragged. Defaults to false.
        ///   - resistance: How easy is it to throw the switch into the next position. Defaults to light.
        ///   - toggleTransition: An optional next button state when toggling the connect button's switch. Defaults to nil.
        ///   - onToggle: An optional callback when the switch is flipped. Defaults to nil.
        ///   - onReverse: An optional callback when the switch is flipped but we reversed the animation to end in the start position. Defaults to nil.
        init(isTapEnabled: Bool = false,
             isDragEnabled: Bool = false,
             resistance: Resistance = .light,
             toggleTransition: (() -> Transition)? = nil,
             onToggle: (() -> Void)? = nil,
             onReverse: (() -> Void)? = nil) {
            self.isTapEnabled = isTapEnabled
            self.isDragEnabled = isDragEnabled
            self.resistance = resistance
            self.toggleTransition = toggleTransition
            self.onToggle = onToggle
            self.onReverse = onReverse
        }
    }
    
    /// Wraps the ability to confirm an email address entry.
    struct EmailInteraction {
        
        /// An optional callback when the email address is confirmed.
        var onConfirm: ((String) -> Void)?
    }
    
    /// Wraps the ability to select an object and its action.
    struct SelectInteraction {
        
        /// Whether selection is enabled or not.
        var isTapEnabled: Bool = false
        
        /// An optional callback when the interaction is tapped.
        var onSelect: (() -> Void)?
    }
}
