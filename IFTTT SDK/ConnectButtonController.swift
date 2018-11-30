//
//  ConnectButtonController.swift
//  IFTTT SDK
//
//  Created by Jon Chmura on 9/19/18.
//  Copyright © 2018 IFTTT. All rights reserved.
//

import UIKit
import SafariServices

/// An error occurred, preventing a connect button from completing a service authentication with the `Connection`.
public enum ConnectButtonControllerError: Error {

    /// For some reason we could not create an IFTTT account for a new user.
    case iftttAccountCreationFailed

    /// Some generic networking error occurred.
    case networkError(Error?)

    /// A user canceled the service authentication with the `Connection`. This happens when the user cancels from the sign in process on an authorization page in a safari view controller.
    case canceled

    /// Redirect parameters did not match what we expected. This should never happen. Verify you are using the latest SDK.
    case unknownRedirect

    /// Response parameters did not match what we expected. This should never happen. Verify you are using the latest SDK.
    case unknownResponse
}

/// Defines the communication between ConnectButtonController and your app. It is required to implement this protocol.
@available(iOS 10.0, *)
public protocol ConnectButtonControllerDelegate: class {

    /// The `ConnectButtonController` needs to present a view controller. This includes the About IFTTT page and Safari VC during Connection activation.
    ///
    /// - Parameter connectButtonController: The `ConnectButtonController` controller that is sending the message.
    /// - Returns: A `UIViewController` to present other view controllers on.
    func presentingViewController(for connectButtonController: ConnectButtonController) -> UIViewController

    /// Connection activation is finished.
    ///
    /// On success, the controller transitions the button to its connected state. It is recommended that you fetch or refresh the user's IFTTT token after successfully authenticating a connection.
    ///
    /// On failure, the controller resets the button to its initial state but does not present any error message.
    /// It is up to you to decided how to present an error message to your user. You may use our message or one you provide.
    ///
    /// For these two scenarios it's not neccessary for you to show additional confirmation, however, you may
    /// want to update your app's UI in some way or ask they user why they canceled if you recieve a canceled error.
    ///
    /// - Parameters:
    ///   - connectButtonController: The `ConnectButtonController` controller that is sending the message.
    ///   - result: A result of the connection activation request.
    func connectButtonController(_ connectButtonController: ConnectButtonController, didFinishActivationWithResult result: Result<Connection>)

    /// Connection deactivation is finished.
    ///
    /// On success, the controller transitions the button to its deactivated initial state.
    ///
    /// On failure, the controller will reset the Connection to the connected state but will not show any messaging. The user attempted to deactivate the Connection but something unexpected went wrong, likely a network failure. It is up to you to do this. This should be rare but should be handled.
    ///
    /// - Parameters:
    ///   - connectButtonController: The `ConnectButtonController` controller that is sending the message.
    ///   - result: A result of the connection deactivation request.
    func connectButtonController(_ connectButtonController: ConnectButtonController, didFinishDeactivationWithResult result: Result<Connection>)

    /// The controller recieved an invalid email from the user. The default implementation of this function is to do nothing.
    ///
    /// - Parameters:
    ///   - connectButtonController: The `ConnectButtonController` controller that is sending the message.
    ///   - email: The invalid email `String` provided by the user.
    func connectButtonController(_ connectButtonController: ConnectButtonController, didRecieveInvalidEmail email: String)
}

@available(iOS 10.0, *)
public extension ConnectButtonControllerDelegate {
    func connectButtonController(_ connectButtonController: ConnectButtonController, didRecieveInvalidEmail email: String) { }
}

/// A controller that handles the `ConnectButton` when authenticating a `Connection`. It is mandatory that you interact with the ConnectButton only through this controller.
@available(iOS 10.0, *)
public class ConnectButtonController {

    /// The connect button in this interaction
    public let button: ConnectButton

    /// The `Connection` the controller is handling. The controller may change the `Connection.Status` of the `Connection`.
    public private(set) var connection: Connection

    private func appletChangedStatus(isOn: Bool) {
        self.connection.status = isOn ? .enabled : .disabled

        if isOn {
            delegate?.connectButtonController(self, didFinishActivationWithResult: .success(connection))
        } else {
            delegate?.connectButtonController(self, didFinishDeactivationWithResult: .success(connection))
        }
    }

    /// The service that is being connected to the primary (owner) service
    /// This defines the service icon & brand color of the button in its initial and final (activated) states
    /// It is always the first service connected
    public var connectingService: Connection.Service {
        return connection.worksWithServices.first ?? connection.primaryService
    }

    /// An `ConnectButtonControllerDelegate` object that will recieved messages about events that happen on the `ConnectButtonController`.
    public private(set) weak var delegate: ConnectButtonControllerDelegate?

    private let connectionConfiguration: ConnectionConfiguration
    private let connectionNetworkController = ConnectionNetworkController()
    private let serviceIconNetworkController = ServiceIconsNetworkController()
    private let tokenProvider: CredentialProvider

    /// Creates a new `ConnectButtonController`.
    ///
    /// - Parameters:
    ///   - connectButton: The `ConnectButton` that the controller is handling interaction for.
    ///   - connectionConfiguration: The `ConnectionConfiguration` with information for authenticating a `Connection`.
    ///   - delegate: A `ConnectInteractionDelegate` to respond to various events that happen on the controller.
    public init(connectButton: ConnectButton, connectionConfiguration: ConnectionConfiguration, delegate: ConnectButtonControllerDelegate) {
        self.button = connectButton
        self.connectionConfiguration = connectionConfiguration
        self.connection = connectionConfiguration.connection
        self.tokenProvider = connectionConfiguration.credentialProvider
        self.delegate = delegate
        setupConnection(for: connection)
    }

    private func setupConnection(for connection: Connection) {
        button.imageViewNetworkController = serviceIconNetworkController
        serviceIconNetworkController.prefetchImages(for: connection)
        
        button.footerInteraction.onSelect = { [weak self] in
            self?.showAboutPage()
        }

        switch connection.status {
        case .initial, .unknown:
            transition(to: .initial)

        case .enabled, .disabled:
            transition(to: .connected)
        }
    }

    private var initialButtonState: ConnectButton.State {
        return .toggle(for: connectingService.connectButtonService,
                       message: "button.state.connect".localized(arguments: connectingService.name),
                       isOn: false)
    }

    private var connectedButtonState: ConnectButton.State {
        return .toggle(for: connectingService.connectButtonService,
                       message: "button.state.connected".localized,
                       isOn: true)
    }

    private func present(_ viewController: UIViewController) {
        let presentingViewController = delegate?.presentingViewController(for: self)
        presentingViewController?.present(viewController, animated: true, completion: nil)
    }


    // MARK: - Footer

    private func showAboutPage() {
        let aboutViewController = AboutViewController(primaryService: connection.primaryService, secondaryService: connection.worksWithServices.first)
        present(aboutViewController)
    }

    enum FooterMessages {
        case
        poweredBy,
        enterEmail,
        emailInvalid,
        signedIn(username: String),
        connect(Connection.Service, to: Connection.Service),
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

        private struct QueryItems {
            static let nextStep = "next_step"
            static let serviceAuthentication = "service_authentication"
            static let serviceId = "service_id"
            static let complete = "complete"
            static let config = "config"
            static let error = "error"
            static let errorType = "error_type"
            static let errorTypeAccountCreation = "account_creation"
        }

        /// Authorization redirect encodes some information about what comes next in the flow
        ///
        /// - serviceConnection: In the next step, authorize a service.
        /// - complete: The Connection is complete. `didConfiguration` is true, if the Connection required a configuration step on web.
        /// - canceled: Service connection or IFTTT login was canceled by closing Safari VC.
        /// - failed: An error occurred on web, aborting the flow.
        enum Outcome {
            case serviceAuthorization(id: String)
            case complete(didConfiguration: Bool)
            case canceled
            case failed(ConnectButtonControllerError)
        }

        var onRedirect: ((Outcome) -> Void)?

        override init() {
            super.init()
            NotificationCenter.default.addObserver(forName: .authorizationRedirect, object: nil, queue: .main) { [weak self] notification in
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
                let nextStep = queryItems.first(where: { $0.name == QueryItems.nextStep })?.value
                else {
                    onRedirect?(.failed(.unknownRedirect))
                    return
            }
            switch nextStep {
            case QueryItems.serviceAuthentication:
                if let serviceId = queryItems.first(where: { $0.name == QueryItems.serviceId })?.value {
                    onRedirect?(.serviceAuthorization(id: serviceId))
                } else {
                    onRedirect?(.failed(.unknownRedirect))
                }
            case QueryItems.complete:
                let didConfiguration = queryItems.first(where: { $0.name == QueryItems.config })?.value == "true"
                onRedirect?(.complete(didConfiguration: didConfiguration))

            case QueryItems.error:
                if let reason = queryItems.first(where: { $0.name == QueryItems.errorType })?.value, reason == QueryItems.errorTypeAccountCreation {
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
        present(controller)
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

        // Did the Connection on web include a configuration step
        var didConfiguration = false

        // Determine the next step based on the redirect result
        let nextStep: ActivationStep = {
            switch outcome {
            case .canceled:
                return .canceled

            case .failed(let error):
                return .failed(error)

            case .serviceAuthorization(let id):
                if let service = connection.services.first(where: { $0.id == id }) {
                    // If service connection comes after a redirect we must have already completed user log in or account creation
                    // Therefore newUserEmail is always nil here
                    return .serviceAuthentication(service, newUserEmail: nil)
                } else {
                    // For some reason, the service ID we received from web doesn't match the connection
                    // If this ever happens, it is due to a bug on web
                    return .failed(.unknownRedirect)
                }
            case .complete(let _didConfiguration):
                didConfiguration = _didConfiguration
                return .connected
            }
        }()

        switch nextStep {
        case .canceled, .failed:
            transition(to: nextStep)

        default:
            switch currentActivationStep {
            case .logInExistingUser?:
                if didConfiguration {
                    transition(to: .connectionConfigurationComplete(connectingService))
                } else {
                    // Show the animation for log in complete before moving on to the next step
                    transition(to: .logInComplete(nextStep: nextStep))
                }

            case .serviceAuthentication(let previousService, _)?:
                if didConfiguration {
                    transition(to: .connectionConfigurationComplete(previousService))
                } else {
                    // Show the animation for service connection before moving on to the next step
                    transition(to: .serviceAuthenticationComplete(previousService,
                                                                  nextStep: nextStep))
                }

            default:
                transition(to: nextStep)
            }
        }
    }


    // MARK: - Connection activation & deactivation

    /// Defines the `Connection` authorization state machine
    ///
    /// - initial: The `Connection` is in the initial state (not authorized)
    /// - identifyUser: We will have an email address or an IFTTT service token. Use this information to determine if they are already an IFTTT user. Obviously they are if we have an IFTTT token, but we still need to get their username.
    /// - logInExistingUser: Ensure that the user is logged into IFTTT in Safari VC. This is required even if we have a user token.
    /// - logInComplete: User was successfully logged in to IFTTT in Safari VC. `nextStep` specifies what come next in the flow. It originates from the authorization redirect.
    /// - serviceAuthentication: Authorize one of this `Connection`s services
    /// - serviceConnectionComplete: Service authorization was successful. `nextStep` specifies what come next in the flow. It originates from the authorization redirect.
    /// - failed: The `Connection` could not be authorized due to some error.
    /// - canceled: The `Connection` authorization was canceled.
    /// - connectionConfigurationComplete: This state always preceeds `connected` when the `Connection` required configuration on web. It includes the `Service` which was configured.
    /// - connected: The `Connection` was successfully authorized.
    /// - confirmDisconnect: The "Slide to disconnect" state, asking for the user's confirmation to disable the `Connection`.
    /// - processDisconnect: Disable the `Connection`.
    /// - disconnected: The `Connection` was disabled.
    indirect enum ActivationStep {
        case initial
        case identifyUser(User.LookupMethod)
        case logInExistingUser(User.Id)
        case logInComplete(nextStep: ActivationStep)
        case serviceAuthentication(Connection.Service, newUserEmail: String?)
        case serviceAuthenticationComplete(Connection.Service, nextStep: ActivationStep)
        case connectionConfigurationComplete(Connection.Service)
        case failed(ConnectButtonControllerError)
        case canceled
        case connected
        case confirmDisconnect
        case processDisconnect
        case disconnected
    }

    /// State machine state
    private var currentActivationStep: ActivationStep?

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
                if self.tokenProvider.iftttServiceToken != nil {
                    return .buttonState(.toggle(for: self.connectingService.connectButtonService, message: "", isOn: true))
                } else {
                    return .buttonState(.email(suggested: self.connectionConfiguration.suggestedUserEmail),
                                        footerValue: FooterMessages.enterEmail.value)
                }
            }
            button.toggleInteraction.onToggle = { [weak self] isOn in
                if let token = self?.tokenProvider.iftttServiceToken {
                    self?.transition(to: .identifyUser(.token(token)))
                }
            }
            button.emailInteraction.onConfirm = { [weak self] email in
                guard let self = self else {
                    assertionFailure("It is expected that `self` is not nil here.")
                    return
                }

                if email.isValidEmail {
                    self.transition(to: .identifyUser(.email(email)))
                } else {
                    self.delegate?.connectButtonController(self, didRecieveInvalidEmail: email)
                    self.button.animator(for: .footerValue(FooterMessages.emailInvalid.value)).preform()
                    self.button.performInvalidEmailAnimation()
                }
            }


        // MARK: - Connected button state
        case (_, .connected):
            let animated = previous != nil

            button.animator(for: .buttonState(connectedButtonState,
                                              footerValue: FooterMessages.manage.value)
                ).preform(animated: animated)

            button.footerInteraction.isTapEnabled = true

            // Connection was changed to this state, not initialized with it, so let the delegate know
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

            connectionNetworkController.getConnectConfiguration(user: lookupMethod, waitUntil: 1, timeout: timeout) { user, error in
                guard let user = user else {
                    self.transition(to: .failed(.networkError(error)))
                    return
                }

                if case .email(let email) = user.id, user.isExistingUser == false {
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
                            self.transition(to: .serviceAuthentication(self.connectingService, newUserEmail: email))
                        }
                    }
                } else { // Existing IFTTT user
                    progress.resume(with: UISpringTimingParameters(dampingRatio: 1), duration: 0.25)
                    progress.onComplete {
                        self.transition(to: .logInExistingUser(user.id))
                    }
                }
            }


        // MARK: - Log in an exisiting user
        case (_, .logInExistingUser(let userId)):
            openActivationURL(connection.activationURL(for: .login(userId), tokenProvider: connectionConfiguration.credentialProvider, activationRedirect: connectionConfiguration.connectAuthorizationRedirectURL))

        case (.logInExistingUser?, .logInComplete(let nextStep)):
            let animation = button.animator(for: .buttonState(.stepComplete(for: nil)))
            animation.onComplete {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    self.transition(to: nextStep)
                }
            }
            animation.preform()

        case (.logInExistingUser?, .connectionConfigurationComplete(let service)):
            connectionConfigurationCompleted(service: service.connectButtonService)

        // MARK: - Service connection
        case (_, .serviceAuthentication(let service, let newUserEmail)):
            let footer = service == connection.primaryService ?
                FooterMessages.poweredBy : FooterMessages.connect(service, to: connection.primaryService)

            button.animator(for: .buttonState(.step(for: service.connectButtonService,
                                                    message: "button.state.sign_in".localized(arguments: service.name)),
                                              footerValue: footer.value)
                ).preform()

            let token = service.id == connection.primaryService.id ? tokenProvider.partnerOAuthCode : nil

            let url = connection.activationURL(for: .serviceConnection(newUserEmail: newUserEmail, token: token), tokenProvider: connectionConfiguration.credentialProvider, activationRedirect: connectionConfiguration.connectAuthorizationRedirectURL)

            button.stepInteraction.isTapEnabled = true
            button.stepInteraction.onSelect = { [weak self] in
                self?.openActivationURL(url)
            }

        case (.serviceAuthentication?, .serviceAuthenticationComplete(let service, let nextStep)):
            button.animator(for: .buttonState(.step(for: service.connectButtonService,
                                                    message: "button.state.connecting".localized),
                                              footerValue: FooterMessages.poweredBy.value)
                ).preform()

            let progressBar = button.progressBar(timeout: 2)
            progressBar.preform()
            progressBar.onComplete {
                self.button.animator(for: .buttonState(.stepComplete(for: service.connectButtonService))).preform()
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    self.transition(to: nextStep)
                }
            }

        case (.serviceAuthentication?, .connectionConfigurationComplete(let service)):
            connectionConfigurationCompleted(service: service.connectButtonService)

        // MARK: - Cancel & failure states
        case (_, .canceled):
            delegate?.connectButtonController(self, didFinishActivationWithResult: .failure(ConnectButtonControllerError.canceled))
            transition(to: .initial)

        case (_, .failed(let error)):
            delegate?.connectButtonController(self, didFinishActivationWithResult: .failure(error))
            transition(to: .initial)


        // MARK: - Disconnect
        case (.connected?, .confirmDisconnect):
            // The user must slide to deactivate the Connection
            button.toggleInteraction.isTapEnabled = false
            button.toggleInteraction.isDragEnabled = true
            button.toggleInteraction.resistance = .heavy

            DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                if case .confirmDisconnect? = self.currentActivationStep {
                    // Revert state if user doesn't follow through
                    self.transition(to: .connected)
                }
            }

            let nextState: ConnectButton.State = .toggle(for: connectingService.connectButtonService,
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

            let request = Connection.Request.disconnectConnection(with: connection.id, credentialProvider: connectionConfiguration.credentialProvider)
            connectionNetworkController.start(urlRequest: request.urlRequest, waitUntil: 1, timeout: timeout) { response in
                progress.resume(with: UISpringTimingParameters(dampingRatio: 1), duration: 0.25)
                progress.onComplete {
                    switch response.result {
                    case .success:
                        self.transition(to: .disconnected)
                    case .failure(let error):
                        self.delegate?.connectButtonController(self, didFinishDeactivationWithResult: .failure(error))
                        self.transition(to: .connected)
                    }
                }
            }

        case (.processDisconnect?, .disconnected):
            appletChangedStatus(isOn: false)

            button.animator(for: .buttonState(.toggle(for: connectingService.connectButtonService,
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


    /// Show confirmation that `Connection` configuration was successfully saved.
    /// This is something that happens on web if the `Connection` required some configuration.
    /// It is not neccessarily preceeded by a `Service` authentication. It is possible that all `Service`s were
    /// already authenticated. In that case this will be preceeded by identify user and IFTTT log in for Safari VC.
    ///
    /// This will automatically transition to the `connected` state.
    ///
    /// - Parameter service: The service that was configured.
    func connectionConfigurationCompleted(service: ConnectButton.Service) {
        button.animator(for: .buttonState(.step(for: service,
                                                message: "button.state.saving_configuration".localized),
                                          footerValue: FooterMessages.poweredBy.value)
            ).preform()

        let progressBar = button.progressBar(timeout: 2)
        progressBar.preform()
        progressBar.onComplete {
            self.button.animator(for: .buttonState(.stepComplete(for: service))).preform()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                self.transition(to: .connected)
            }
        }
    }
}


// MARK: - Service icons downloader

private class ServiceIconsNetworkController: ImageViewNetworkController {
    let downloader = ImageDownloader()
    
    /// Prefetch and cache service icon images for this `Connection`.
    /// This will be it very unlikely that an image is delayed and visually "pops in".
    func prefetchImages(for connection: Connection) {
        connection.services.forEach {
            downloader.downloadImage(url: $0.templateIconURL, { _ in})
            downloader.downloadImage(url: $0.standardIconURL, { _ in})
        }
    }
    
    var currentRequests = [UIImageView : URLSessionDataTask]()
    
    func setImage(with url: URL?, for imageView: UIImageView) {
        if let existingTask = currentRequests[imageView] {
            if existingTask.originalRequest?.url == url {
                return // This is a duplicate request
            } else {
                // The image url was changed
                existingTask.cancel()
                currentRequests[imageView] = nil
            }
        }
        
        imageView.image = nil
        if let url = url {
            let task = downloader.downloadImage(url: url) { (result) in
                switch result {
                case .success(let image):
                    imageView.image = image
                case .failure:
                    // Images that fail to load are left blank
                    // Since we attempt to precatch images, this is actually the second try
                    break
                }
            }
            currentRequests[imageView] = task
        }
    }
}


// MARK: - Convenience

@available(iOS 10.0, *)
private extension Connection.Service {
    var connectButtonService: ConnectButton.Service {
        return ConnectButton.Service(standardIconURL: standardIconURL, brandColor: brandColor)
    }
}
