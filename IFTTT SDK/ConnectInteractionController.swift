//
//  ConnectInteractionController.swift
//  IFTTT SDK
//
//  Created by Jon Chmura on 9/19/18.
//  Copyright © 2018 IFTTT. All rights reserved.
//

import UIKit
import SafariServices

public enum ConnectInteractionOutcome {
    case
    activated(Applet),
    disabled(Applet),
    canceled,
    failed(Error)
}

public protocol ConnectInteractionControllerDelegate: class {
    func connectInteraction(_ controller: ConnectInteractionController, show viewController: UIViewController)
    func connectInteraction(_ controller: ConnectInteractionController, appletActivationFinished outcome: ConnectInteractionOutcome)
}

public class ConnectInteractionController {
    
    /// The connect button in this interaction
    public let button: ConnectButton
    
    /// The Applet in this interaction
    /// The controller may change the connection status of the Applet
    public private(set) var applet: Applet
    
    private func appletChangedStatus(isOn: Bool) {
        applet.updating(status: isOn ? .enabled : .disabled)
        if isOn {
            delegate?.connectInteraction(self, appletActivationFinished: .activated(applet))
        } else {
            delegate?.connectInteraction(self, appletActivationFinished: .disabled(applet))
        }
    }
    
    /// The service that is being connected to the primary (owner) service
    /// This defines the service icon & brand color of the button in its initial and final (activated) states
    /// It is always the first service connected
    public let connectingService: Applet.Service
    
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
    
    private var initialButtonState: ConnectButton.State {
        return .toggle(
            for: connectingService,
            message: "button.state.connect".localized(arguments: connectingService.name),
            isOn: false)
    }
    
    private var activatedButtonState: ConnectButton.State {
        return .toggle(for: connectingService,
                       message: "button.state.connected".localized,
                       isOn: true)
    }
    
    
    // MARK: - Footer
    
    /// When the connect button is in the "toggle" state, the user may select it to open the about page
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
        // Before we continue and handle this redirect, we must dismiss the active Safari VC
        guard currentSafariViewController == nil else {
            // In this case the user dismissed Safari on their own by tapping the dismiss button
            // This is a user cancel, but we have to wait for the VC to finish dismissing
            // We can do this by monitoring the VC transition coordinator
            if let transitionCoordinator = currentSafariViewController?.transitionCoordinator, currentSafariViewController?.isBeingDismissed == true {
                transitionCoordinator.animate(alongsideTransition: { _ in }) { (_) in
                    // Transition coordinator completion
                    self.currentSafariViewController = nil
                    self.handleRedirect(outcome)
                }
            } else {
                // We must have gotten here from a redirect which doesn't automatically dismiss Safari VC
                // Do that first
                currentSafariViewController?.dismiss(animated: true, completion: {
                    self.currentSafariViewController = nil
                    self.handleRedirect(outcome)
                })
            }
            return
        }
        
        // Determine the next step based on the redirect result
        let nextStep: ActivationStep = {
            switch outcome {
            case .canceled:
                return .canceled
                
            case .failed:
                // FIXME: Build a error message
                return .failed(NSError())
                
            case .serviceConnection(let id):
                if let service = applet.services.first(where: { $0.id == id }) {
                    // If service connection comes after a redirect we must have already completed user log in or account creation
                    // Therefore newUserEmail is always nil here
                    return .serviceConnection(service, newUserEmail: nil)
                } else {
                    // For some reason, the service ID we received from web doesn't match the applet
                    // If this ever happens, it is due to a bug on web
                    // FIXME: Set an appropriate error message.
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
                // Show the animation for log in complete before moving on to the next step
                transition(to: .logInComplete(nextStep: nextStep))
                
            case .serviceConnection(let previousService, _)?:
                // Show the animation for service connection before moving on to the next step
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
        
        let previous = currentActivationStep
        self.currentActivationStep = step
        
        switch (previous, step) {
            
        // MARK: - Initial connect button state
        case (.none, .start), (.canceled?, .start), (.failed?, .start):
            redirectObserving = RedirectObserving()
            redirectObserving?.onRedirect = { [weak self] outcome in
                self?.handleRedirect(outcome)
            }
            
            footerSelect.isEnabled = true
            
            let animated = previous != nil
            
            let transition = button.transition(to: initialButtonState)
            if animated {
                transition.preform()
            } else {
                transition.preformWithoutAnimation()
            }
            button.configureFooter(FooterMessages.poweredBy.value, animated: animated)
            
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
            button.transition(to: activatedButtonState).preform()
            button.configureFooter(FooterMessages.manage.value, animated: true)
            footerSelect.isEnabled = true
            
            // Updates our local copy of this Applet to indicate that it has been updated and inform the delegate
            appletChangedStatus(isOn: true)
            
        case (_, .canceled):
            delegate?.connectInteraction(self, appletActivationFinished: .canceled)
            transition(to: .start)
            
        case (_, .failed(let error)):
            delegate?.connectInteraction(self, appletActivationFinished: .failed(error))
            transition(to: .start)
            
        default:
            fatalError("Invalid state transition")
        }
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
