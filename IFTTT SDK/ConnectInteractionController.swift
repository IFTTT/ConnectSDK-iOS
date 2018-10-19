//
//  ConnectInteractionController.swift
//  IFTTT SDK
//
//  Created by Jon Chmura on 9/19/18.
//  Copyright © 2018 IFTTT. All rights reserved.
//

import UIKit
import SafariServices

public extension Notification.Name {
    static var iftttAppletActivationRedirect: Notification.Name {
        return Notification.Name("ifttt.applet.activation.redirect")
    }
}

public protocol ConnectInteractionControllerDelegate: class {
    func connectInteraction(_ controller: ConnectInteractionController, show viewController: UIViewController)
    func connectInteractionUserCanceledAppletActivation(_ controller: ConnectInteractionController)
    func connectInteraction(_ controller: ConnectInteractionController, appletActivationFailedWithError error: Error)
}

public class ConnectInteractionController {
    
    public weak var delegate: ConnectInteractionControllerDelegate?
    
    public init(_ button: ConnectButton, applet: Applet, delegate: ConnectInteractionControllerDelegate) {
        self.button = button
        self.applet = applet
        self.delegate = delegate
        self.connectingService = applet.worksWithServices.first ?? applet.primaryService
        
        footerSelect = Selectable(button.footerLabel) { [weak self] in
            self?.showAboutPage()
        }
        
        switch applet.status {
        case .initial, .unknown:
            transition(to: .start)
            
        case .enabled, .disabled:
            break // FIXME: Build toggle interaction !!
        }
    }
    
    
    // MARK: - Footer
    
    private var footerSelect: Selectable!
    
    private func showAboutPage() {
        delegate?.connectInteraction(self,
                                     show: AboutViewController(primaryService: applet.primaryService,
                                                               secondaryService: applet.worksWithServices.first))
    }
    
    enum FooterMessages {
        case
        poweredBy,
        enterEmail,
        signedIn(username: String),
        connect(Applet.Service, to: Applet.Service),
        manage
        
        private var typestyle: Typestyle { return .footnote }
        
        private var iftttText: NSAttributedString {
            return NSAttributedString(string: "IFTTT",
                                      attributes: [.font : typestyle.adjusting(weight: .heavy).font])
        }
        
        var value: NSAttributedString {
            switch self {
            case .poweredBy:
                let text = NSMutableAttributedString(string: "button.footer.powered_by".localized,
                                                     attributes: [.font : typestyle.adjusting(weight: .bold).font])
                text.append(iftttText)
                return text
            
            case .enterEmail:
                let text = "button.footer.email".localized
                return NSAttributedString(string: text, attributes: [.font : typestyle.font])
                
            case .signedIn(let username):
                let text = NSMutableAttributedString(string: username,
                                                     attributes: [.font: typestyle.adjusting(weight: .bold).font])
                text.append(NSAttributedString(string: "button.footer.signed_in".localized,
                                               attributes: [.font : typestyle.font]))
                text.append(iftttText)
                return text
                
            case .connect(let fromService, let toService):
                let text = String(format: "button.footer.connect".localized, fromService.name, toService.name)
                return NSAttributedString(string: text, attributes: [.font : typestyle.font])
                
            case .manage:
                let text = NSMutableAttributedString(string: "button.footer.manage".localized,
                                                     attributes: [.font : typestyle.font])
                text.append(iftttText)
                return text
            }
        }
    }
    
    let button: ConnectButton
    
    let applet: Applet
    
    let connectingService: Applet.Service
    
    
    // MARK: - New applet activation
    
    indirect enum ActivationStep {
        enum UserId {
            case id(String), email(String)
        }
        
        case
        start,
        getUserId,
        checkEmailIsExistingUser(String),
        logInExistingUser(User.ID),
        logInComplete(nextStep: ActivationStep),
        serviceConnection(Applet.Service, newUserEmail: String?),
        serviceConnectionComplete(Applet.Service, nextStep: ActivationStep),
        failed(Error),
        canceled,
        complete
    }
    
    private var currentActivationStep: ActivationStep?
    
    private var currentSafariViewController: SFSafariViewController?
    
    private var redirectObserving: RedirectObserving?
    
    private func handleRedirect(_ outcome: RedirectObserving.Outcome) {
        guard currentSafariViewController == nil else {
            currentSafariViewController?.dismiss(animated: true, completion: {
                self.currentSafariViewController = nil
                self.handleRedirect(outcome)
            })
            return
        }
        
        let nextStep: ActivationStep = {
            switch outcome {
            case .canceled:
                return .canceled
            case .failed:
                // FIXME: Build a error message
                return .failed(NSError())
            case .serviceConnection(let id):
                if let service = applet.services.first(where: { $0.id == id }) {
                    // At this point in the flow, we must have already logged in the user or created their account
                    return .serviceConnection(service, newUserEmail: nil)
                } else {
                    // FIXME: This should never happen but maybe there's a bug in the web flow. Set an appropriate error message.
                    return .failed(NSError())
                }
            case .complete:
                return .complete
            }
        }()
        
        switch nextStep {
        case .canceled, .failed:
            transition(to: nextStep)
        default:
            switch currentActivationStep {
            case .logInExistingUser?:
                transition(to: .logInComplete(nextStep: nextStep))
            case .serviceConnection(let previousService, _)?:
                transition(to: .serviceConnectionComplete(previousService,
                                                          nextStep: nextStep))
            default:
                transition(to: nextStep)
            }
        }
    }
    
    private func transition(to step: ActivationStep) {
        
        // Cleanup
        button.nextToggleState = nil
        button.onToggle = nil
        button.onEmailConfirmed = nil
        button.onStepSelected = nil
        button.onStateChanged = nil
        
        switch (currentActivationStep, step) {
            
        // MARK: - Initial connect button state
        case (.none, .start):
            redirectObserving = RedirectObserving()
            redirectObserving?.onRedirect = { [weak self] outcome in
                self?.handleRedirect(outcome)
            }
            
            footerSelect.isEnabled = true
            
            // FIXME: What service shows here?
            button.transition(to: .toggle(
                for: connectingService,
                message: "button.state.connect".localized(arguments: connectingService.name),
                isOn: false)
                ).preformWithoutAnimation()
            button.configureFooter(FooterMessages.poweredBy.value, animated: false)
            
            button.nextToggleState = {
                if let _ = Applet.Session.shared.userToken {
                    // User is already logged in to IFTTT
                    // Retrieve their user ID and skip email step
                    return .step(for: nil, message: "button.state.accessing_existing_account", isSelectable: false)
                } else {
                    return .email(suggested: User.current.suggestedUserEmail)
                }
            }
            button.onToggle = { [weak self] isOn in
                if let _ = Applet.Session.shared.userToken {
                    self?.transition(to: .getUserId)
                } else {
                    self?.button.configureFooter(FooterMessages.enterEmail.value, animated: false)
                }
            }
            button.onEmailConfirmed = { [weak self] email in
                self?.transition(to: .checkEmailIsExistingUser(email))
            }
            
            
        // MARK: - Get user ID from user token
        case (.start?, .getUserId):
            // FIXME: Make a request to /me to get user id
            break
            
            
        // MARK: - Check if email is an existing user
        case (.start?, .checkEmailIsExistingUser(let email)):
            footerSelect.isEnabled = false
            
            let timeout: TimeInterval = 4 // How many seconds we'll wait before giving up and opening the applet activation URL
            
            button.transition(to:
                .step(for: nil,
                      message: "button.state.checking_account".localized,
                      isSelectable: false)
                ).preform()
            
            let progress = button.progressTransition(timeout: timeout)
            progress.preform()
            
            var isExisting = true
            User.check(email: email, timeout: timeout) { (_isExisting) in
                isExisting = _isExisting
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                if isExisting {
                    // There exists an IFTTT account for this user
                    // Finish the progress bar animation and open web to login
                    progress.resume(with: UICubicTimingParameters(animationCurve: .easeIn), duration: 0.5)
                    progress.onComplete {
                        self.transition(to: .logInExistingUser(.email(email)))
                    }
                } else {
                    // There is no account for this user
                    // Show a fake message that we are creating an account
                    // Then move to the first step of the service connection flow
                    self.button.transition(to:
                        .step(for: nil,
                              message: "button.state.creating_account".localized,
                              isSelectable: false)
                        ).preform()
                    
                    progress.resume(with: UICubicTimingParameters(animationCurve: .easeIn), duration: 1.5)
                    progress.onComplete {
                        // Show "fake" success
                        self.button.transition(to: .stepComplete(for: nil)).preform()
                        
                        // After a short delay, show first service connection
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            // We know that this is a new user so we must connect the primary service first and create an account
                            self.transition(to: .serviceConnection(self.applet.primaryService, newUserEmail: email))
                        }
                    }
                }
            }
            
        case (_, .logInExistingUser(let userId)):
            let url = applet.activationURL(.login(userId))
            let controller = SFSafariViewController(url: url, entersReaderIfAvailable: false)
            controller.delegate = redirectObserving
            currentSafariViewController = controller
            delegate?.connectInteraction(self, show: controller)
            
        case (.logInExistingUser?, .logInComplete(let nextStep)):
            let transition = button.transition(to: .stepComplete(for: nil))
            transition.onComplete {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    self.transition(to: nextStep)
                }
            }
            transition.preform()
            
        case (_, .serviceConnection(let service, let newUserEmail)):
            button.transition(to:
                .step(for: service,
                      message: "button.state.sign_in".localized(arguments: service.name),
                      isSelectable: true)
                ).preform()
            
            let url = applet.activationURL(.serviceConnection(newUserEmail: newUserEmail))
            button.onStepSelected = { [weak self] in
                self?.button.onStepSelected = nil
                let controller = SFSafariViewController(url: url, entersReaderIfAvailable: false)
                controller.delegate = self?.redirectObserving
                self?.currentSafariViewController = controller
                if let strongSelf = self {
                    strongSelf.delegate?.connectInteraction(strongSelf, show: controller)
                }
            }
            
        case (.serviceConnection?, .serviceConnectionComplete(let service, let nextStep)):
            button.transition(to: .step(for: service, message: "button.state.saving".localized, isSelectable: false)).preform()
            button.configureFooter(FooterMessages.poweredBy.value, animated: true)
            
            let progressBar = button.progressTransition(timeout: 2)
            progressBar.preform()
            progressBar.onComplete {
                self.button.transition(to: .stepComplete(for: service)).preform()
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    self.transition(to: nextStep)
                }
            }
            
        case (_, .complete):
            // FIXME: What service shows here?
            button.transition(to:
                .toggle(for: connectingService,
                        message: "button.state.connected".localized,
                        isOn: true)
                ).preform()
            button.configureFooter(FooterMessages.manage.value, animated: true)
            footerSelect.isEnabled = true
            
        case (_, .canceled):
            // FIXME: Reset the button
            delegate?.connectInteractionUserCanceledAppletActivation(self)
            
        case (_, .failed(let error)):
            // FIXME: Reset the button and build an informative error
            delegate?.connectInteraction(self, appletActivationFailedWithError: error)
            
        default:
            fatalError("Invalid state transition")
        }
        
        self.currentActivationStep = step
    }
}


// MARK: - Safari redirect observing

extension ConnectInteractionController {
    class RedirectObserving: NSObject, SFSafariViewControllerDelegate {
        
        enum Outcome {
            case
            serviceConnection(id: String),
            complete,
            canceled,
            failed
        }
        
        var onRedirect: ((Outcome) -> Void)?
        
        override init() {
            super.init()
            NotificationCenter.default.addObserver(forName: .iftttAppletActivationRedirect, object: nil, queue: .main) { [weak self] notification in
                self?.handleRedirect(notification)
            }
        }
        
        deinit {
            NotificationCenter.default.removeObserver(self)
        }
        
        private func handleRedirect(_ notification: Notification) {
            guard
                let url = notification.object as? URL,
                let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
                let queryItems = components.queryItems,
                let nextStep = queryItems.first(where: { $0.name == "next_step" })?.value
                else {
                    onRedirect?(.failed)
                    return
            }
            switch nextStep {
            case "service_connection":
                if let serviceId = queryItems.first(where: { $0.name == "service_id" })?.value {
                    onRedirect?(.serviceConnection(id: serviceId))
                } else {
                    onRedirect?(.failed)
                }
            case "complete":
                onRedirect?(.complete)
            default:
                onRedirect?(.failed)
            }
        }
        
        func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
            onRedirect?(.canceled)
        }
    }
}
