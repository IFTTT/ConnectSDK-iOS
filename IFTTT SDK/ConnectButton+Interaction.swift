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
    
    struct ToggleInteraction {
        // How easy is it to throw the switch into the next position
        enum Resistance {
            case light, heavy
            
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
        
        /// Can the switch be tapped
        var isTapEnabled: Bool
        
        /// Can the switch be dragged
        var isDragEnabled: Bool
        
        var resistance: Resistance
        
        /// What is the next button state when switching the toggle
        var toggleTransition: (() -> Transition)?
        
        /// Callback when switch is toggled
        var onToggle: (() -> Void)?
        
        /// Callback when the switch is toggled but we reversed the animation to end in the start position
        var onReverse: (() -> Void)?
        
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
    
    struct EmailInteraction {
        /// Callback when the email address is confirmed
        var onConfirm: ((String) -> Void)?
    }
    
    struct SelectInteraction {
        var isTapEnabled: Bool = false
        
        var onSelect: (() -> Void)?
    }
    
}
