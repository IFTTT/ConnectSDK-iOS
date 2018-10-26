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
    succeeded(Applet),
    canceled,
    failed(Error)
}

/// Defines the communication between ConnectInteractionController and your app. It is required to implement this protocol.
public protocol ConnectInteractionControllerDelegate: class {
    
    /// The connect interaction needs to present a view controller
    /// This includes the About IFTTT page and Safari VC during Applet activation
    /// Implementation is required
    ///
    /// - Parameters:
    ///   - controller: The connect interaction controller
    ///   - viewController: The view controller to present
    func connectInteraction(_ interation: ConnectInteractionController, show viewController: UIViewController)
    
    /// Applet activation is finished
    ///
    /// On succeeded, the connect interaction transitions the button to its connected state.
    /// On canceled, the connect interaction resets the button to its initial state.
    ///
    /// For these two scenarios it's not neccessary for you to show additional confirmation, however, you may
    /// want to update your app's UI in some way or ask they user why they canceled.
    ///
    /// On failed, the connect interaction resets the button to its initial state but does not present any error message.
    /// It is up to you to decided how to present an error message to your user. You may use our message or one you provide.
    ///
    /// - Parameters:
    ///   - interation: The connect interaction controller
    ///   - outcome: The outcome of Applet activation
    func connectInteraction(_ interation: ConnectInteractionController, appletActivationFinished outcome: ConnectInteractionOutcome)
    
    /// The user deactivated the Applet
    ///
    /// - Parameters:
    ///   - interation: The connect interaction controller
    ///   - appletDeactivated: The Applet which was deactivated
    func connectInteraction(_ interation: ConnectInteractionController, appletDeactivated applet: Applet)
    
    /// The user attempted to deactivate the Applet but something unexpected went wrong, likely a network failure.
    /// The connect interaction will reset the Applet to the connected state but will not show any messaging.
    /// It is up to you to do this. This should be rare but should be handled.
    ///
    /// - Parameters:
    ///   - interation: The connect interaction controller
    ///   - error: The error
    func connectInteraction(_ interation: ConnectInteractionController, appletDeactivationFailedWithError error: Error)
}


/// Controller for the ConnectButton. It is mandatory that you interact with the ConnectButton only through this controller.
public class ConnectInteractionController {
    
    /// The connect button in this interaction
    public let button: ConnectButton
    
    /// The Applet in this interaction
    /// The controller may change the connection status of the Applet
    public private(set) var applet: Applet
    
    private func appletChangedStatus(isOn: Bool) {
        applet.updating(status: isOn ? .enabled : .disabled)
        if isOn {
            delegate?.connectInteraction(self, appletActivationFinished: .succeeded(applet))
        } else {
            delegate?.connectInteraction(self, appletDeactivated: applet)
        }
    }
    
    /// The service that is being connected to the primary (owner) service
    /// This defines the service icon & brand color of the button in its initial and final (activated) states
    /// It is always the first service connected
    public let connectingService: Applet.Service
    
    public private(set) weak var delegate: ConnectInteractionControllerDelegate?
    
    public init(_ button: ConnectButton, applet: Applet, delegate: ConnectInteractionControllerDelegate) {
        self.button = button
        self.applet = applet
        self.delegate = delegate
        self.connectingService = applet.worksWithServices.first ?? applet.primaryService

        button.footerInteraction.onSelect = { [weak self] in
            self?.showAboutPage()
        }

        switch applet.status {
        case .initial, .unknown:
            transition(to: .initial)

        case .enabled, .disabled:
            transition(to: .connected)
        }
    }
    
    private var initialButtonState: ConnectButton.State {
        return .toggle(
            for: connectingService,
            message: "button.state.connect".localized(arguments: connectingService.name),
            isOn: false)
    }
    
    private var connectedButtonState: ConnectButton.State {
        return .toggle(for: connectingService,
                       message: "button.state.connected".localized,
                       isOn: true)
    }
    
    
    // MARK: - Footer
    
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
        manage,
        disconnect
        
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
                
            case .disconnect:
                return NSAttributedString(string: "button.footer.disconnect".localized,
                                          attributes: [.font : typestyle.font])
            }
        }
    }
    
    
    // MARK: - Safari VC and redirect handling
    
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
    
    private var currentSafariViewController: SFSafariViewController?
    
    private func openActivationURL(_ url: URL) {
        let controller = SFSafariViewController(url: url, entersReaderIfAvailable: false)
        controller.delegate = redirectObserving
        currentSafariViewController = controller
        delegate?.connectInteraction(self, show: controller)
    }
    
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
                return .connected
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
    
    
    // MARK: - Applet activation & deactivation
    
    indirect enum ActivationStep {
        enum UserId {
            case id(String), email(String)
        }
        
        case
        initial,
        
        getUserId,
        checkEmailIsExistingUser(String),
        
        logInExistingUser(User.ID),
        logInComplete(nextStep: ActivationStep),
        
        serviceConnection(Applet.Service, newUserEmail: String?),
        serviceConnectionComplete(Applet.Service, nextStep: ActivationStep),
        
        failed(Error),
        canceled,
        
        connected,
        
        confirmDisconnect,
        processDisconnect,
        disconnected
    }
    
    /// State machine state
    private var currentActivationStep: ActivationStep?
    
    private var currentConfiguration: Applet.Session.ConnectConfiguration?
    
    /// State machine handling Applet activation and deactivation
    private func transition(to step: ActivationStep) {
        
        // Cleanup
        button.toggleInteraction = .init()
        button.emailInteraction = .init()
        button.stepInteraction = .init()
        button.footerInteraction.isTapEnabled = false // Don't clear the select block
        
        let previous = currentActivationStep
        self.currentActivationStep = step
        
        switch (previous, step) {
            
        // MARK: - Initial connect button state
        case (.none, .initial), (.canceled?, .initial), (.failed?, .initial), (.disconnected?, .initial):
            redirectObserving = RedirectObserving()
            redirectObserving?.onRedirect = { [weak self] outcome in
                self?.handleRedirect(outcome)
            }
            
            button.footerInteraction.isTapEnabled = true
            
            let animated = previous != nil
            
            button.transition(to: initialButtonState).preform(animated: animated)
            button.configureFooter(FooterMessages.poweredBy.value, animated: animated)
            
            button.toggleInteraction.isTapEnabled = true
            button.toggleInteraction.isDragEnabled = true
            
            button.toggleInteraction.nextToggleState = {
//                if let _ = Applet.Session.shared.userToken {
//                    // User is already logged in to IFTTT
//                    // Retrieve their user ID and skip email step
//                    return .step(for: nil, message: "button.state.accessing_existing_account".localized)
//                } else {
                    return .email(suggested: User.current.suggestedUserEmail)
//                }
            }
            button.toggleInteraction.onToggle = { [weak self] isOn in
                if let _ = Applet.Session.shared.userToken {
                    self?.transition(to: .getUserId)
                } else {
                    self?.button.configureFooter(FooterMessages.enterEmail.value, animated: false)
                }
            }
            button.emailInteraction.onConfirm = { [weak self] email in
                self?.transition(to: .checkEmailIsExistingUser(email))
            }
            
            
        // MARK: - Connected button state
        case (_, .connected):
            let animated = previous != nil
            
            button.transition(to: connectedButtonState).preform(animated: animated)
            button.configureFooter(FooterMessages.manage.value, animated: animated)
            
            button.footerInteraction.isTapEnabled = true
            
            // Applet was changed to this state, not initialized with it, so let the delegate know
            if previous != nil {
                appletChangedStatus(isOn: true)
            }
            
            button.toggleInteraction.isTapEnabled = true
            
            let nextState = connectedButtonState
            button.toggleInteraction.nextToggleState = {
                return nextState
            }
            button.toggleInteraction.onToggle = { [weak self] _ in
                self?.transition(to: .confirmDisconnect)
            }
            
            
        // MARK: - Get user ID from user token
        case (.initial?, .getUserId):
            // FIXME: Make a request to /me to get user id
            break
            
            
        // MARK: - Check if email is an existing user
        case (.initial?, .checkEmailIsExistingUser(let email)):
            let timeout: TimeInterval = 3 // Network request timeout
            
            button.transition(to:
                .step(for: nil,
                      message: "button.state.checking_account".localized)
                ).preform()
            
            let progress = button.progressTransition(timeout: timeout)
            progress.preform()
            
            Applet.Session.shared.getConnectConfiguration(userEmail: email,
                                                          waitUntil: 1,
                                                          timeout: timeout)
            { (configuration) in
                self.currentConfiguration = configuration
                
                if configuration.isExistingUser {
                    progress.resume(with: UISpringTimingParameters(dampingRatio: 1), duration: 0.25)
                    progress.onComplete {
                        self.transition(to: .logInExistingUser(.email(email)))
                    }
                } else {
                    // There is no account for this user
                    // Show a fake message that we are creating an account
                    // Then move to the first step of the service connection flow
                    self.button.transition(to:
                        .step(for: nil,
                              message: "button.state.creating_account".localized)
                        ).preform()
                    
                    progress.resume(with: UISpringTimingParameters(dampingRatio: 1), duration: 1.5)
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

            
        // MARK: - Log in an exisiting user
        case (_, .logInExistingUser(let userId)):
            openActivationURL(applet.activationURL(.login(userId)))
            
        case (.logInExistingUser?, .logInComplete(let nextStep)):
            let transition = button.transition(to: .stepComplete(for: nil))
            transition.onComplete {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    self.transition(to: nextStep)
                }
            }
            transition.preform()
            
            
        // MARK: - Service connection
        case (_, .serviceConnection(let service, let newUserEmail)):
            button.transition(to:
                .step(for: service,
                      message: "button.state.sign_in".localized(arguments: service.name))
                ).preform()
            
            let token: String? = {
                if service.id == applet.primaryService.id {
                    return currentConfiguration?.partnerOpaqueToken
                }
                return nil
            }()
            
            let url = applet.activationURL(.serviceConnection(newUserEmail: newUserEmail, token: token))
            button.stepInteraction.isTapEnabled = true
            button.stepInteraction.onSelect = { [weak self] in
                self?.openActivationURL(url)
            }
            
        case (.serviceConnection?, .serviceConnectionComplete(let service, let nextStep)):
            //FIXME: The web needs to tell us whether to say connecting or saving here
            button.transition(to: .step(for: service, message: "button.state.connecting".localized)).preform()
            button.configureFooter(FooterMessages.poweredBy.value, animated: true)

            let progressBar = button.progressTransition(timeout: 2)
            progressBar.preform()
            progressBar.onComplete {
                self.button.transition(to: .stepComplete(for: service)).preform()
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    self.transition(to: nextStep)
                }
            }
        
            
        // MARK: - Cancel & failure states
        case (_, .canceled):
            delegate?.connectInteraction(self, appletActivationFinished: .canceled)
            transition(to: .initial)
            
        case (_, .failed(let error)):
            delegate?.connectInteraction(self, appletActivationFinished: .failed(error))
            transition(to: .initial)
            
            
        // MARK: - Disconnect
        case (.connected?, .confirmDisconnect):
            // The user must slide to deactivate the Applet
            button.toggleInteraction.isTapEnabled = false
            button.toggleInteraction.isDragEnabled = true
            button.toggleInteraction.resistance = .heavy
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                if case .confirmDisconnect? = self.currentActivationStep {
                    // Revert state if user doesn't follow through
                    self.transition(to: .connected)
                }
            }
            
            let nextState: ConnectButton.State = .toggle(for: connectingService,
                                                         message: "button.state.disconnecting".localized,
                                                         isOn: false)
            button.toggleInteraction.nextToggleState = {
                return nextState
            }
            button.toggleInteraction.onToggle = { [weak self] isOn in
                if isOn {
                    self?.transition(to: .connected)
                } else {
                    self?.transition(to: .processDisconnect)
                }
            }
            
            button.configureFooter(FooterMessages.disconnect.value, animated: true)
            
        case (.confirmDisconnect?, .processDisconnect):
            let timeout: TimeInterval = 3 // Network request timeout
            
            let progress = button.progressTransition(timeout: timeout)
            progress.preform()
            
            Applet.Request.disconnectApplet(id: applet.id) { (response) in
                progress.resume(with: UISpringTimingParameters(dampingRatio: 1), duration: 0.25)
                progress.onComplete {
                    switch response.result {
                    case .success:
                        self.transition(to: .disconnected)
                    case .failure(let error):
                        // FIXME: Create error message
                        self.delegate?.connectInteraction(self, appletDeactivationFailedWithError: error ?? NSError())
                        self.transition(to: .connected)
                    }
                }
            }.start(waitUntil: 1, timeout: timeout)
            
        case (.processDisconnect?, .disconnected):
            appletChangedStatus(isOn: false)
            
            button.transition(to: .toggle(for: connectingService,
                                          message: "button.state.disconnected".localized,
                                          isOn: false)).preform()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                self.transition(to: .initial)
            }
            
        default:
            fatalError("Invalid state transition")
        }
    }
}
