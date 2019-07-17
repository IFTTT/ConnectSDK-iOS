//
//  ConnectButton+Transition.swift
//  IFTTT SDK
//
//  Copyright © 2019 IFTTT. All rights reserved.
//

import Foundation

@available(iOS 10.0, *)
extension ConnectButton {
    
    /// Groups button State and footer value into a single state transition
    struct Transition {
        
        /// An optional `AnimationState` to transition to.
        let state: AnimationState?
        
        /// An optional `LabelValue` to update the footer to.
        let footerValue: LabelValue?
        
        /// How long the transition should take.
        let duration: TimeInterval
        
        /// Creates a `Transition` for the connect button.
        ///
        /// - Parameters:
        ///   - state: An `AnimationState` to transition the connect button to.
        ///   - duration: How long the transition should take. Defaults to 0.4 seconds.
        /// - Returns: A configured `Transition`.
        static func buttonState(_ state: AnimationState, duration: TimeInterval = 0.4) -> Transition {
            return Transition(state: state, footerValue: nil, duration: duration)
        }
        
        /// Creates a `Transition` for the connect button.
        ///
        /// - Parameters:
        ///   - state: An `AnimationState` to transition the connect button to.
        ///   - footerValue: A `LabelValue` to update the footer to.
        ///   - duration: How long the transition should take. Defaults to 0.4 seconds.
        /// - Returns: A configured `Transition`.
        static func buttonState(_ state: AnimationState, footerValue: LabelValue, duration: TimeInterval = 0.4) -> Transition {
            return Transition(state: state, footerValue: footerValue, duration: duration)
        }
        
        /// Creates a footer `Transition` for the connect button.
        ///
        /// - Parameters:
        ///   - value: A `LabelValue` to update the footer to.
        ///   - duration: How long the transition should take. Defaults to 0.4 seconds.
        /// - Returns: A configured `Transition`.
        static func footerValue(_ value: LabelValue, duration: TimeInterval = 0.4) -> Transition {
            return Transition(state: nil, footerValue: value, duration: duration)
        }
    }
    
}
