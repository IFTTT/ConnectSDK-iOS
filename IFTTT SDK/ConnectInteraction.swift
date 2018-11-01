//
//  ConnectInteractionController.swift
//  IFTTT SDK
//
//  Created by Jon Chmura on 9/19/18.
//  Copyright © 2018 IFTTT. All rights reserved.
//

import UIKit
import SafariServices

/// An error occurred, preventing Applet connection
///
/// - invalidEmail: Must provide a valid email.
/// - iftttAccountCreationFailed: For some reason we could not create an IFTTT account for a new user.
/// - networkError: Some generic networking error occurred.
/// - unknownRedirect: Redirect params did not match what we expected. This should never happen. Verify you are using the latest SDK.
/// - unknownResponse: Response params did not match what we expected. This should never happen. Verify you are using the latest SDK.
public enum AppletConnectionError: Error {
    case invalidEmail(String)
    case iftttAccountCreationFailed
    case networkError(Error?)
    case unknownRedirect
    case unknownResponse
}

/// The result of an attempt to turn on an Applet
///
/// - succeeded: The Applet was successfully connected
/// - canceled: The user canceled connection attempt
/// - failed: Some error prevented the user from connecting the Applet
public enum AppletConnectionOutcome {
    case succeeded(Applet)
    case canceled
    case failed(AppletConnectionError)
}

/// Defines the communication between ConnectInteractionController and your app. It is required to implement this protocol.
public protocol ConnectInteractionDelegate: class {
    
    /// The connect interaction needs to present a view controller
    /// This includes the About IFTTT page and Safari VC during Applet activation
    /// Implementation is required
    ///
    /// - Parameters:
    ///   - controller: The connect interaction controller
    ///   - viewController: The view controller to present
    func connectInteraction(_ interation: ConnectInteraction, show viewController: UIViewController)
    
    func connectInteraction(_ interaction: ConnectInteraction, nonFatalActivationError error: AppletConnectionError)
    
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
    func connectInteraction(_ interation: ConnectInteraction, appletActivationFinished outcome: AppletConnectionOutcome)
    
    /// The user deactivated the Applet
    ///
    /// - Parameters:
    ///   - interation: The connect interaction controller
    ///   - appletDeactivated: The Applet which was deactivated
    func connectInteraction(_ interation: ConnectInteraction, appletDeactivated applet: Applet)
    
    /// The user attempted to deactivate the Applet but something unexpected went wrong, likely a network failure.
    /// The connect interaction will reset the Applet to the connected state but will not show any messaging.
    /// It is up to you to do this. This should be rare but should be handled.
    ///
    /// - Parameters:
    ///   - interation: The connect interaction controller
    ///   - error: The error
    func connectInteraction(_ interation: ConnectInteraction, appletDeactivationFailedWithError error: AppletConnectionError)
}


/// Controller for the ConnectButton. It is mandatory that you interact with the ConnectButton only through this controller.
public class ConnectInteraction {
    
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
    
    public private(set) weak var delegate: ConnectInteractionDelegate?
    
    public init(_ button: ConnectButton, applet: Applet, delegate: ConnectInteractionDelegate) {
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
        emailInvalid,
        signedIn(username: String),
        connect(Applet.Service, to: Applet.Service),
        manage,
        disconnect
        
        private var typestyle: Typestyle { return .footnote }
        
        private var iftttText: NSAttributedString {
            return NSAttributedString(string: "IFTTT",
                                      attributes: [.font : typestyle.adjusting(weight: .heavy).font])
        }
        
        var value: ConnectButton.LabelValue {
            return .attributed(attributedString)
        }
        
        var attributedString: NSAttributedString {
            switch self {
            case .poweredBy:
                let text = NSMutableAttributedString(string: "button.footer.powered_by".localized,
                                                     attributes: [.font : typestyle.adjusting(weight: .bold).font])
                text.append(iftttText)
                return text
            
            case .enterEmail:
                let text = "button.footer.email".localized
                return NSAttributedString(string: text, attributes: [.font : typestyle.font])
                
            case .emailInvalid:
                let text = "button.footer.email.invalid".localized
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
            failed(AppletConnectionError)
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
                    onRedirect?(.failed(.unknownRedirect))
                    return
            }
            switch nextStep {
            case "service_connection":
                if let serviceId = queryItems.first(where: { $0.name == "service_id" })?.value {
                    onRedirect?(.serviceConnection(id: serviceId))
                } else {
                    onRedirect?(.failed(.unknownRedirect))
                }
            case "complete":
                onRedirect?(.complete)
                
            case "error":
                if let reason = queryItems.first(where: { $0.name == "error_type" })?.value, reason == "account_creation" {
                    onRedirect?(.failed(.iftttAccountCreationFailed))
                } else {
                    onRedirect?(.failed(.unknownRedirect))
                }
                
            default:
                onRedirect?(.failed(.unknownRedirect))
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
        if #available(iOS 11.0, *) {
            controller.dismissButtonStyle = .cancel
        } 
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
                
            case .failed(let error):
                return .failed(error)
                
            case .serviceConnection(let id):
                if let service = applet.services.first(where: { $0.id == id }) {
                    // If service connection comes after a redirect we must have already completed user log in or account creation
                    // Therefore newUserEmail is always nil here
                    return .serviceConnection(service, newUserEmail: nil)
                } else {
                    // For some reason, the service ID we received from web doesn't match the applet
                    // If this ever happens, it is due to a bug on web
                    return .failed(.unknownRedirect)
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
        case
        initial,
        
        identifyUser(ConnectConfiguration.UserLookupMethod),
        
        logInExistingUser(User.Id),
        logInComplete(nextStep: ActivationStep),
        
        serviceConnection(Applet.Service, newUserEmail: String?),
        serviceConnectionComplete(Applet.Service, nextStep: ActivationStep),
        
        failed(AppletConnectionError),
        canceled,
        
        connected,
        
        confirmDisconnect,
        processDisconnect,
        disconnected
    }
    
    /// State machine state
    private var currentActivationStep: ActivationStep?
    
    private var currentConfiguration: ConnectConfiguration?
    
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
            
            button.animator(for:
                .buttonState(initialButtonState, footerValue: FooterMessages.poweredBy.value)
            ).preform(animated: animated)
            
            button.toggleInteraction.isTapEnabled = true
            button.toggleInteraction.isDragEnabled = true
            
            button.toggleInteraction.toggleTransition = {
                if let _ = Applet.Session.shared.userToken {
                    return .buttonState(.toggle(for: self.connectingService, message: "", isOn: true))
                } else {
                    return .buttonState(.email(suggested: Applet.Session.shared.suggestedUserEmail),
                                        footerValue: FooterMessages.enterEmail.value)
                }
            }
            button.toggleInteraction.onToggle = { [weak self] isOn in
                if let token = Applet.Session.shared.userToken {
                    self?.transition(to: .identifyUser(.token(token)))
                }
            }
            button.emailInteraction.onConfirm = { [weak self] email in
                if email.isValidEmail {
                    self?.transition(to: .identifyUser(.email(email)))
                } else {
                    if let delegate = self?.delegate {
                        delegate.connectInteraction(self!, nonFatalActivationError: .invalidEmail(email))
                    }
                    self?.button.animator(for: .footerValue(FooterMessages.emailInvalid.value)).preform()
                    self?.button.performInvalidEmailAnimation()
                }
            }
            
            
        // MARK: - Connected button state
        case (_, .connected):
            let animated = previous != nil
            
            button.animator(for: .buttonState(connectedButtonState,
                                              footerValue: FooterMessages.manage.value)
            ).preform(animated: animated)
            
            button.footerInteraction.isTapEnabled = true
            
            // Applet was changed to this state, not initialized with it, so let the delegate know
            if previous != nil {
                appletChangedStatus(isOn: true)
            }
            
            // Toggle from here goes to disconnection confirmation
            // When the user taps the switch, they are asked to confirm disconnection by dragging the switch into the off position
            button.toggleInteraction.isTapEnabled = true
            
            // The next toggle state is still the connected state since the user will confirm as part of the next step
            // We only change the footer to "slide to disconnect"
            let nextState = connectedButtonState
            button.toggleInteraction.toggleTransition = {
                return .buttonState(nextState,
                                    footerValue: FooterMessages.disconnect.value)
            }
            button.toggleInteraction.onToggle = { [weak self] _ in
                self?.transition(to: .confirmDisconnect)
            }
            
            
        // MARK: - Check if email is an existing user
        case (.initial?, .identifyUser(let lookupMethod)):
            let timeout: TimeInterval = 3 // Network request timeout
            
            switch lookupMethod {
            case .email:
                button.animator(for: .buttonState(.step(for: nil,
                                                        message: "button.state.checking_account".localized),
                                                  footerValue: FooterMessages.poweredBy.value)
                ).preform()
                
            case .token:
                button.animator(for: .buttonState(.step(for: nil,
                                                        message: "button.state.accessing_existing_account".localized),
                                                  footerValue: FooterMessages.poweredBy.value)
                ).preform()
            }
            
            let progress = button.progressBar(timeout: timeout)
            progress.preform()
            
            Applet.Session.shared.getConnectConfiguration(user: lookupMethod,
                                                          waitUntil: 1,
                                                          timeout: timeout)
            { (configuration, error) in
                guard let configuration = configuration else {
                    self.transition(to: .failed(.networkError(error)))
                    return
                }
                self.currentConfiguration = configuration
                
                if case .email(let email) = configuration.userId, configuration.isExistingUser == false {
                    // There is no account for this user
                    // Show a fake message that we are creating an account
                    // Then move to the first step of the service connection flow
                    self.button.animator(for: .buttonState(.step(for: nil,
                                                                 message: "button.state.creating_account".localized))
                    ).preform()
                    
                    progress.resume(with: UISpringTimingParameters(dampingRatio: 1), duration: 1.5)
                    progress.onComplete {
                        // Show "fake" success
                        self.button.animator(for: .buttonState(.stepComplete(for: nil))).preform()
                        
                        // After a short delay, show first service connection
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            // We know that this is a new user so we must connect the primary service first and create an account
                            self.transition(to: .serviceConnection(self.applet.primaryService, newUserEmail: email))
                        }
                    }
                } else { // Existing IFTTT user
                    progress.resume(with: UISpringTimingParameters(dampingRatio: 1), duration: 0.25)
                    progress.onComplete {
                        self.transition(to: .logInExistingUser(configuration.userId))
                    }
                }
            }

            
        // MARK: - Log in an exisiting user
        case (_, .logInExistingUser(let userId)):
            openActivationURL(applet.activationURL(.login(userId)))
            
        case (.logInExistingUser?, .logInComplete(let nextStep)):
            let animation = button.animator(for: .buttonState(.stepComplete(for: nil)))
            animation.onComplete {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    self.transition(to: nextStep)
                }
            }
            animation.preform()
            
            
        // MARK: - Service connection
        case (_, .serviceConnection(let service, let newUserEmail)):
            let footer = service == applet.primaryService ?
                FooterMessages.poweredBy : FooterMessages.connect(service, to: applet.primaryService)
            
            button.animator(for: .buttonState(.step(for: service,
                                                    message: "button.state.sign_in".localized(arguments: service.name)),
                                              footerValue: footer.value)
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
            button.animator(for: .buttonState(.step(for: service, message: "button.state.connecting".localized),
                                              footerValue: FooterMessages.poweredBy.value)
            ).preform()

            let progressBar = button.progressBar(timeout: 2)
            progressBar.preform()
            progressBar.onComplete {
                self.button.animator(for: .buttonState(.stepComplete(for: service))).preform()
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
            button.toggleInteraction.toggleTransition = {
                return .buttonState(nextState,
                                    footerValue: .none)
            }
            button.toggleInteraction.onToggle = { [weak self] isOn in
                if isOn {
                    self?.transition(to: .connected)
                } else {
                    self?.transition(to: .processDisconnect)
                }
            }
            
        case (.confirmDisconnect?, .processDisconnect):
            let timeout: TimeInterval = 3 // Network request timeout
            
            let progress = button.progressBar(timeout: timeout)
            progress.preform()
            
            Applet.Request.disconnectApplet(id: applet.id) { (response) in
                progress.resume(with: UISpringTimingParameters(dampingRatio: 1), duration: 0.25)
                progress.onComplete {
                    switch response.result {
                    case .success:
                        self.transition(to: .disconnected)
                    case .failure(let error):
                        self.delegate?.connectInteraction(self, appletDeactivationFailedWithError: .networkError(error))
                        self.transition(to: .connected)
                    }
                }
            }.start(waitUntil: 1, timeout: timeout)
            
        case (.processDisconnect?, .disconnected):
            appletChangedStatus(isOn: false)
            
            button.animator(for: .buttonState(.toggle(for: connectingService,
                                                      message: "button.state.disconnected".localized,
                                                      isOn: false))
            ).preform()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                self.transition(to: .initial)
            }
            
        default:
            fatalError("Invalid state transition")
        }
    }
}
