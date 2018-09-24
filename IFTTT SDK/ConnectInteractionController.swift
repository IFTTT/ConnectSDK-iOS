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
        
        button.transition(to: .toggle(for: applet.worksWithServices.first!, message: "Connect \(self.applet.worksWithServices.first!.name)", isOn: false)).preformWithoutAnimation()
    }
    
    public func begin() {
        button.nextToggleState = {
            return .email
        }
        button.onEmailConfirmed = { [weak self] email in
            print(email)
            self?.beginLoading()
        }
        button.onStepSelected = { [weak self] in
            self?.connectService()
        }
    }
    
    private func beginLoading() {
        let queue = DispatchQueue.main
        
        button.transition(to: .step(for: nil, message: "Checking for IFTTT account...", isSelectable: false)).preform()
        
        let progressBar = button.progressTransition(timeout: 4)
        progressBar.preform()
        
        queue.asyncAfter(deadline: .now() + 2) {
            self.button.transition(to: .step(for: nil, message: "Creating IFTTT account...", isSelectable: false)).preform()
            
            // API call to check IFTTT acconut is finished, set new duration
            progressBar.resume(with: UICubicTimingParameters(animationCurve: .easeIn), durationAdjustment: 2)
        }
        
        queue.asyncAfter(deadline: .now() + 4) {
            self.button.transition(to: .stepComplete(for: nil)).preform()
        }
        
        queue.asyncAfter(deadline: .now() + 6) {
            self.button.transition(to: .step(for: self.applet.worksWithServices.first!, message: "Sign in to \(self.applet.worksWithServices.first!.name)", isSelectable: true)).preform()
        }
    }
    
    private func connectService() {
        let queue = DispatchQueue.main
        
        button.transition(to: .step(for: applet.worksWithServices.first!, message: "Saving settings...", isSelectable: false)).preform()
        
        let progressBar = button.progressTransition(timeout: 2)
        progressBar.preform()
        
        queue.asyncAfter(deadline: .now() + 2) {
            self.button.transition(to: .stepComplete(for: self.applet.worksWithServices.first!)).preform()
        }
        
        queue.asyncAfter(deadline: .now() + 4) {
            self.button.transition(to: .toggle(for: self.applet.worksWithServices.first!, message: "Connected", isOn: true)).preform()
        }
    }
}
