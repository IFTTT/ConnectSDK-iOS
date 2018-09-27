//
//  ConnectInteractionController.swift
//  IFTTT SDK
//
//  Created by Jon Chmura on 9/19/18.
//  Copyright © 2018 IFTTT. All rights reserved.
//

import UIKit
import AuthenticationServices
import SafariServices

public class ConnectInteractionController {
    
    enum FooterMessages {
        case
        poweredBy,
        enterEmail,
        signedIn(username: String),
        connect(Applet.Service, to: Applet.Service),
        manage
        
        private var iftttText: NSAttributedString {
            return NSAttributedString(string: "IFTTT", attributes: [.font : UIFont.ifttt(.footnoteHeavy)])
        }
        
        var value: NSAttributedString {
            switch self {
            case .poweredBy:
                let text = NSMutableAttributedString(string: "POWERED BY ",
                                                     attributes: [.font : UIFont.ifttt(.footnoteBold)])
                text.append(iftttText)
                return text
            
            case .enterEmail:
                let text = "Sign in to IFTTT or create a new account"
                return NSAttributedString(string: text, attributes: [.font : UIFont.ifttt(.footnote)])
                
            case .signedIn(let username):
                let text = NSMutableAttributedString(string: username,
                                                     attributes: [.font: UIFont.ifttt(.footnoteBold)])
                text.append(NSAttributedString(string: " sign in to ",
                                               attributes: [.font : UIFont.ifttt(.footnote)]))
                text.append(iftttText)
                return text
                
            case .connect(let fromService, let toService):
                let text = "Sign in to connect \(fromService.name) with \(toService.name)"
                return NSAttributedString(string: text, attributes: [.font : UIFont.ifttt(.footnote)])
            case .manage:
                let text = NSMutableAttributedString(string: "You're all set. Manage connection with ",
                                                     attributes: [.font : UIFont.ifttt(.footnote)])
                text.append(iftttText)
                return text
            }
        }
    }
    
    let button: ConnectButton
    
    let applet: Applet
    
    let connectingService: Applet.Service
    
    public init(_ button: ConnectButton, applet: Applet) {
        self.button = button
        self.applet = applet
        self.connectingService = applet.worksWithServices.first ?? applet.primaryService
        
        start()
    }
    
    private func start() {
        switch applet.status {
        case .initial, .unknown:
            button.transition(to: .toggle(
                for: applet.worksWithServices.first!,
                message: "Connect \(connectingService.name)",
                isOn: false)
                ).preformWithoutAnimation()
            button.configureFooter(FooterMessages.poweredBy.value, animated: false)
            
            button.onStateChanged = { [weak self] state in
                switch state {
                case .email:
                    self?.button.configureFooter(FooterMessages.enterEmail.value, animated: false)
                default:
                    break
                }
            }
            button.nextToggleState = {
                return .email(suggested: User.current.suggestedUserEmail)
            }
            button.onEmailConfirmed = { [weak self] email in
                self?.check(email: email)
            }
            
        case .enabled, .disabled:
            break // FIXME: !!
        }
    }
    
    private func check(email: String) {
        let timeout: TimeInterval = 4 // How many seconds we'll wait before giving up and opening the applet activation URL
        
        button.transition(to:
            .step(for: nil,
                  message: "Checking for IFTTT account...",
                  isSelectable: false)
            ).preform()
        
        let progress = button.progressTransition(timeout: timeout)
        progress.preform()
        
        var isExisting = true
        User.check(email: email, timeout: timeout) { (_isExisting) in
            isExisting = _isExisting
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.finishChecking(email: email, isExisting: isExisting, progress: progress)
        }
    }
    
    private func finishChecking(email: String, isExisting: Bool, progress: ConnectButton.State.Transition) {
        if isExisting {
            progress.resume(with: UICubicTimingParameters(animationCurve: .easeIn), duration: 0.5)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.activationConfirmation(withEmail: email)
            }
        } else {
            button.transition(to:
                .step(for: nil,
                      message: "Creating IFTTT account...",
                      isSelectable: false)
                ).preform()
            progress.resume(with: UICubicTimingParameters(animationCurve: .easeIn), duration: 1.5)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                self.activationConfirmation(withEmail: email)
            }
        }
    }
    
    private func activationConfirmation(withEmail email: String) {
        button.transition(to: .stepComplete(for: nil)).preform()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.button.transition(to:
                .step(for: self.connectingService,
                      message: "Sign in to \(self.connectingService.name)",
                    isSelectable: true)
            ).preform()
        }
        button.onStepSelected = { [weak self] in
            self?.beingActivation(withEmail: email)
            self?.button.onStepSelected = nil
        }
    }
    
    /// We must keep a strong reference to the current authentication session
    /// But make this value `Any` so we don't have any iOS version compatibility issues
    private var currentAuthSession: Any?
    
    private func beingActivation(withEmail email: String) {
        let url = applet.activationURL(forUserEmail: email)
        
        let scheme = Applet.Session.shared.appletActivationRedirect?.scheme
        if #available(iOS 12, *) {
            let session = ASWebAuthenticationSession(url: url, callbackURLScheme: scheme) { (url, error) in
                if let error = error as? ASWebAuthenticationSessionError, error.code == .canceledLogin {
                    self.activationCanceled()
                } else if let url = url {
                    self.activationCompleted(withCallback: url)
                } else { // Unknown issue
                    self.activationUnknownError()
                }
                self.currentAuthSession = nil
            }
            session.start()
            currentAuthSession = session
        } else if #available(iOS 11, *) {
            // This is virtually the same API as ASWebAuthenticationSession but we must use this on iOS 11
            // The following code is indentical to above case
            let session = SFAuthenticationSession(url: url, callbackURLScheme: scheme) { (url, error) in
                if let error = error as? SFAuthenticationError, error.code == .canceledLogin {
                    self.activationCanceled()
                } else if let url = url {
                    self.activationCompleted(withCallback: url)
                } else {
                    self.activationUnknownError()
                }
                self.currentAuthSession = nil
            }
            session.start()
            currentAuthSession = session
        } else {
            
        }
    }
    
    private func activationUnknownError() {
        // FIXME: Send error code to partner app
        button.transition(to: .toggle(
            for: applet.worksWithServices.first!,
            message: "Connect \(connectingService.name)",
            isOn: false)
            ).preformWithoutAnimation()
        button.configureFooter(FooterMessages.poweredBy.value, animated: false)
    }
    
    private func activationCanceled() {
        // FIXME: Send error code to partner app
        button.transition(to: .toggle(
            for: applet.worksWithServices.first!,
            message: "Connect \(connectingService.name)",
            isOn: false)
            ).preformWithoutAnimation()
        button.configureFooter(FooterMessages.poweredBy.value, animated: false)
    }
    
    private func activationCompleted(withCallback url: URL) {
        connectService()
    }
    
    private func connectService() {
        let queue = DispatchQueue.main
        
        button.transition(to: .step(for: applet.worksWithServices.first!, message: "Saving settings...", isSelectable: false)).preform()
        button.configureFooter(FooterMessages.poweredBy.value, animated: true)
        
        let progressBar = button.progressTransition(timeout: 2)
        progressBar.preform()
        
        queue.asyncAfter(deadline: .now() + 2) {
            self.button.transition(to: .stepComplete(for: self.applet.worksWithServices.first!)).preform()
        }
        
        queue.asyncAfter(deadline: .now() + 4) {
            self.button.transition(to: .toggle(for: self.applet.worksWithServices.first!, message: "Connected", isOn: true)).preform()
            self.button.configureFooter(FooterMessages.manage.value, animated: true)
        }
    }
}
