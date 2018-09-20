//
//  ConnectInteractionController.swift
//  IFTTT SDK
//
//  Created by Jon Chmura on 9/19/18.
//  Copyright © 2018 IFTTT. All rights reserved.
//

import UIKit

public class ConnectInteractionController {
    
    let button: ConnectButton
    
    let applet: Applet
    
    public init(_ button: ConnectButton, applet: Applet) {
        self.button = button
        self.applet = applet
        
        button.transition(to: .toggle(for: applet.services.first!, message: "Connect", isOn: false)).preformWithoutAnimation()
    }
    
    public func begin() {
        let queue = DispatchQueue.main
        
        queue.asyncAfter(deadline: .now() + 2) {
            self.button.transition(to: .email).preform()
        }
        
        var progressBar: ConnectButton.State.Transition?
        
        queue.asyncAfter(deadline: .now() + 5) {
            self.button.transition(to: .step(for: nil, message: "Checking for IFTTT account...")).preform()
            progressBar = self.button.progressTransition(timeout: 4)
            progressBar?.preform()
        }
        
        queue.asyncAfter(deadline: .now() + 9) {
            self.button.transition(to: .step(for: nil, message: "Creating IFTTT account...")).preform()
            
            // API call to check IFTTT acconut is finished, set new duration
            progressBar?.resume(with: UICubicTimingParameters(animationCurve: .easeIn), durationAdjustment: 2)
        }
        
        
    }
}
