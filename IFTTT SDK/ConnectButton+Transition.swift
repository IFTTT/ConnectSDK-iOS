//
//  ConnectButton+Transition.swift
//  IFTTT SDK
//
//  Created by Michael Amundsen on 5/23/19.
//  Copyright © 2019 IFTTT. All rights reserved.
//

import Foundation

@available(iOS 10.0, *)
extension ConnectButton {
    
    /// Groups button State and footer value into a single state transition
    struct Transition {
        let state: AnimationState?
        let footerValue: LabelValue?
        let duration: TimeInterval
        
        init(state: AnimationState, duration: TimeInterval) {
            self.state = state
            self.footerValue = nil
            self.duration = duration
        }
        
        init(footerValue: LabelValue, duration: TimeInterval) {
            self.state = nil
            self.footerValue = footerValue
            self.duration = duration
        }
        
        init(state: AnimationState?, footerValue: LabelValue?, duration: TimeInterval) {
            self.state = state
            self.footerValue = footerValue
            self.duration = duration
        }
        
        static func buttonState(_ state: AnimationState, duration: TimeInterval = 0.4) -> Transition {
            return Transition(state: state, footerValue: nil, duration: duration)
        }
        
        static func buttonState(_ state: AnimationState, footerValue: LabelValue, duration: TimeInterval = 0.4) -> Transition {
            return Transition(state: state, footerValue: footerValue, duration: duration)
        }
        
        static func footerValue(_ value: LabelValue, duration: TimeInterval = 0.4) -> Transition {
            return Transition(state: nil, footerValue: value, duration: duration)
        }
    }
    
}
