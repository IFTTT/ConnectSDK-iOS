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
    case networkError(NetworkError)

    /// A user canceled the service authentication with the `Connection`. This happens when the user cancels from the sign in process on an authorization page in a safari view controller.
    case canceled

    /// Redirect parameters did not match what we expected. This should never happen. Verify you are using the latest SDK.
    case unknownRedirect

    /// Response parameters did not match what we expected. This should never happen. Verify you are using the latest SDK.
    case unknownResponse

    /// For some reason the `Connection` used by this controller has gone nil or could not be retrieved. This should never happen.
    case unableToGetConnection
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
    func connectButtonController(_ connectButtonController: ConnectButtonController, didFinishActivationWithResult result: Result<Connection, ConnectButtonControllerError>)

    /// Connection deactivation is finished.
    ///
    /// On success, the controller transitions the button to its deactivated initial state.
    ///
    /// On failure, the controller will reset the Connection to the connected state but will not show any messaging. The user attempted to deactivate the Connection but something unexpected went wrong, likely a network failure. It is up to you to do this. This should be rare but should be handled.
    ///
    /// - Parameters:
    ///   - connectButtonController: The `ConnectButtonController` controller that is sending the message.
    ///   - result: A result of the connection deactivation request.
    func connectButtonController(_ connectButtonController: ConnectButtonController, didFinishDeactivationWithResult result: Result<Connection, ConnectButtonControllerError>)

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
    public private(set) var connection: Connection?

    private func appletChangedStatus(isOn: Bool) {
        guard let connection = connection else {
            return
        }

        self.connection?.status = isOn ? .enabled : .disabled

        if isOn {
            delegate?.connectButtonController(self, didFinishActivationWithResult: .success(connection))
        } else {
            delegate?.connectButtonController(self, didFinishDeactivationWithResult: .success(connection))
        }
    }

    private var credentialProvider: CredentialProvider {
        return connectionConfiguration.credentialProvider
    }

    /// An `ConnectButtonControllerDelegate` object that will recieved messages about events that happen on the `ConnectButtonController`.
    public private(set) weak var delegate: ConnectButtonControllerDelegate?

    private let connectionConfiguration: ConnectionConfiguration
    private let connectionNetworkController = ConnectionNetworkController()
    private let serviceIconNetworkController = ServiceIconsNetworkController()

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
        self.delegate = delegate
        setupConnection(for: connection, animated: false)
    }

    private func setupConnection(for connection: Connection?, animated: Bool) {
        guard let connection = connection else {
            fetchConnection(for: connectionConfiguration.connectionId)
            return
        }

        button.imageViewNetworkController = serviceIconNetworkController
        serviceIconNetworkController.prefetchImages(for: connection)

        button.minimumFooterLabelHeight = FooterMessages.estimatedMaximumTextHeight

        button.configureEmailField(placeholderText: "button.email.placeholder".localized,
                                   confirmButtonAsset: Assets.Button.emailConfirm)

        switch connection.status {
        case .initial, .unknown, .disabled:

            // Disabled Connections are presented in the "Connect" state
            transition(to: .initial(animated: animated))

        case .enabled:
            transition(to: .connected(animated: false))
        }
    }

    private func fetchConnection(for id: String) {
        button.animator(for: .buttonState(.loading)).preform(animated: true)

        connectionNetworkController.start(request: .fetchConnection(for: id, credentialProvider: credentialProvider)) { [weak self] response in
            guard let self = self else { return }

            switch response.result {
            case .success(let connection):
                self.connection = connection
                self.setupConnection(for: connection, animated: true)

            case .failure:
                break
            }
        }
    }

    private func buttonState(forConnectionStatus status: Connection.Status, service: Connection.Service) -> ConnectButton.AnimationState {
        switch status {
        case .initial, .unknown:
            return .connect(service: service.connectButtonService,
                            message: "button.state.connect".localized(with: service.shortName))
        case .disabled:
            return .connect(service: service.connectButtonService,
                            message: "button.state.reconnect".localized(with: service.shortName))
        case .enabled:
            return .connected(service: service.connectButtonService,
                              message: "button.state.connected".localized)
        }
    }

    private func present(_ viewController: UIViewController) {
        let presentingViewController = delegate?.presentingViewController(for: self)
        presentingViewController?.present(viewController, animated: true, completion: nil)
    }


    // MARK: - Footer

    /// Presents the about page
    private func showAboutPage() {
        guard let connection = connection else {
            assertionFailure("It is expected and required that we have a non nil connection in this state.")
            return
        }

        guard let secondaryService = connection.worksWithServices.first else {
            return
        }

        let aboutViewController = AboutViewController(primaryService: connection.primaryService,
                                                      secondaryService: secondaryService)
        present(aboutViewController)
    }

    enum FooterMessages {
        case
        poweredBy,
        enterEmail,
        emailInvalid,
        verifying(email: String),
        signedIn(username: String),
        connect(Connection.Service, to: Connection.Service),
        manage

        private struct Constants {
            static let errorTextColor: UIColor = .red

            static var footnoteFont: UIFont {
                return .footnote()
            }

            static var footnoteBoldFont: UIFont {
                return .footnote(weight: .bold)
            }
        }

        /// Our best guess of the maximum height of the footer label
        fileprivate static var estimatedMaximumTextHeight: CGFloat {
            // We are estimating that the text will never exceed 2 lines (plus some line spacing)
            return 2.1 * Constants.footnoteFont.lineHeight
        }

        private var iftttText: NSAttributedString {
            return NSAttributedString(string: "IFTTT",
                                      attributes: [.font : Constants.footnoteBoldFont])
        }

        var value: ConnectButton.LabelValue {
            return .attributed(attributedString)
        }

        var attributedString: NSAttributedString {

            switch self {
            case .poweredBy:
                let text = NSMutableAttributedString(string: "button.footer.powered_by".localized,
                                                     attributes: [.font : Constants.footnoteBoldFont])
                text.append(iftttText)
                return text

            case .enterEmail:
                let text = "button.footer.email.legal".localized
                return LegalTermsText.string(withPrefix: text, activateLinks: false, attributes: [.font : Constants.footnoteFont])

            case .emailInvalid:
                let text = "button.footer.email.invalid".localized
                return NSAttributedString(string: text, attributes: [.font : Constants.footnoteFont, .foregroundColor : Constants.errorTextColor])

            case .verifying(let email):
                let text = NSMutableAttributedString(string: "button.footer.email.sign_in".localized(with: email), attributes: [.font : Constants.footnoteFont])
                let changeEmailText = NSAttributedString(string: "button.footer.email.change_email".localized, attributes: [.font : Constants.footnoteBoldFont, .underlineStyle : NSUnderlineStyle.single.rawValue])
                text.append(changeEmailText)
                return text

            case .signedIn(let username):
                let text = NSMutableAttributedString(string: username,
                                                     attributes: [.font: Constants.footnoteBoldFont])
                text.append(NSAttributedString(string: "button.footer.signed_in".localized,
                                               attributes: [.font : Constants.footnoteFont]))
                text.append(iftttText)
                return text

            case .connect(let fromService, let toService):
                let text = String(format: "button.footer.connect".localized, fromService.name, toService.name)
                return NSAttributedString(string: text, attributes: [.font : Constants.footnoteFont])

            case .manage:
                let text = NSMutableAttributedString(string: "button.footer.manage".localized,
                                                     attributes: [.font : Constants.footnoteFont])
                text.append(iftttText)
                return text
            }
        }
    }


    // MARK: - Safari VC delegate (cancelation handling)

    /// Delegate object for Safari VC
    /// Handles user cancelation in the web flow
    class SafariDelegate: NSObject, SFSafariViewControllerDelegate {
        /// Callback when the Safari VC is dismissed by the user
        /// This triggers a cancelation event
        let onCancelation: () -> Void

        /// Create a new SafariDelegate
        ///
        /// - Parameter onCancelation: The cancelation handler
        init(onCancelation: @escaping () -> Void) {
            self.onCancelation = onCancelation
        }

        func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
            onCancelation()
        }
    }

    /// This objects acts as the Safari VC delegate
    private var safariDelegate: SafariDelegate?

    private func handleCancelation(lookupMethod: User.LookupMethod) {
        switch lookupMethod {
        case .email:
            transition(to: .enterEmail)
        case .token:
            transition(to: .canceled)
        }
    }


    // MARK: - Safari VC redirect handling

    class RedirectObserving {

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
        /// - failed: An error occurred on web, aborting the flow.
        enum Outcome {
            case serviceAuthorization(id: String)
            case complete(didConfiguration: Bool)
            case failed(ConnectButtonControllerError)
        }

        var onRedirect: ((Outcome) -> Void)?

        init() {
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
    }

    private var redirectObserving: RedirectObserving?

    private func handleRedirect(_ outcome: RedirectObserving.Outcome) {

        // Before we continue and handle this redirect, we must dismiss the active Safari VC
        guard currentSafariViewController == nil else {
            // Redirect doesn't automatically dismiss Safari VC
            // Do that first
            currentSafariViewController?.dismiss(animated: true) {
                self.currentSafariViewController = nil
                self.handleRedirect(outcome)
            }
            return
        }

        // Determine the next step based on the redirect result
        let nextStep: ActivationStep = {
            switch outcome {
            case .failed(let error):
                return .failed(error)

            case .serviceAuthorization(let id):
                guard let connection = connection else {
                    assertionFailure("It is expected and required that we have a non nil connection in this state.")
                    return .failed(.unableToGetConnection)
                }

                if let service = connection.services.first(where: { $0.id == id }) {
                    // If service connection comes after a redirect we must have already completed user log in or account creation
                    // Therefore newUserEmail is always nil here
                    return .serviceAuthentication(service, newUserEmail: nil)
                } else {
                    // For some reason, the service ID we received from web doesn't match the connection
                    // If this ever happens, it is due to a bug on web
                    return .failed(.unknownRedirect)
                }
            case .complete:
                return .authenticationComplete
            }
        }()

        transition(to: nextStep)
    }


    // MARK: - Web flow (IFTTT log in and service activation)

    private var currentSafariViewController: SFSafariViewController?

    private func openActivationURL(_ url: URL) {
        let controller = SFSafariViewController(url: url, entersReaderIfAvailable: false)
        controller.delegate = safariDelegate
        if #available(iOS 11.0, *) {
            controller.dismissButtonStyle = .cancel
        }
        currentSafariViewController = controller
        present(controller)
    }

    /// Creates a `RedirectObserving` and a `SafariDelegate` to track interaction in the web portion of the activation flow
    private func prepareActivationWebFlow(lookupMethod: User.LookupMethod) {
        redirectObserving = RedirectObserving()
        redirectObserving?.onRedirect = { [weak self] outcome in
            self?.handleRedirect(outcome)
        }

        safariDelegate = SafariDelegate { [weak self] in
            self?.handleCancelation(lookupMethod: lookupMethod)
        }
    }

    /// Once activation is finished or canceled, tear down redirect and cancelation observing
    private func endActivationWebFlow() {
        redirectObserving = nil
        safariDelegate = nil
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
    enum ActivationStep {
        case initial(animated: Bool)
        case enterEmail
        case identifyUser(User.LookupMethod)
        case logInExistingUser(User.Id)
        case serviceAuthentication(Connection.Service, newUserEmail: String?)
        case authenticationComplete
        case failed(ConnectButtonControllerError)
        case canceled
        case connected(animated: Bool)
        case confirmDisconnect
        case processDisconnect
        case disconnected
    }

    /// Wraps various tasks associated with accessing an account so they can be tracked or interrupted.
    private struct AccessAccountTask {
        let progressAnimation: ConnectButton.Animator
        let dataTask: URLSessionDataTask
    }

    private var accessAccountTask: AccessAccountTask?

    /// State machine handling Applet activation and deactivation
    private func transition(to step: ActivationStep) {
        guard let connection = connection else {
            assertionFailure("It is required to have a non nil `Connection` in order to handle activation and deactivation.")
            return
        }

        // Cleanup
        button.toggleInteraction = .init()
        button.emailInteraction = .init()
        button.stepInteraction = .init()
        button.footerInteraction.isTapEnabled = false // Don't clear the select block

        switch step {
        case .initial(let animated):
            transitionToInitalization(connection: connection, animated: animated)
        case .enterEmail:
            self.transition(to: .initial(animated: false))
            self.button.animator(for: .buttonState(.enterEmail(suggestedEmail: self.connectionConfiguration.suggestedUserEmail), footerValue: FooterMessages.enterEmail.value)).preform()
        case .identifyUser(let lookupMethod):
            transitionToIdentifyUser(connection: connection, lookupMethod: lookupMethod)
        case .logInExistingUser(let userId):
            transitionToLogInExistingUser(userId: userId)
        case .serviceAuthentication(let service, let newUserEmail):
            transitionToServiceAuthentication(service: service, newUserEmail: newUserEmail)
        case .authenticationComplete:
            transitionToAuthenticationComplete()
        case .failed(let error):
            transitionToFailed(error: error)
        case .canceled:
            transitionToCanceled(connection: connection)
        case .connected(let animated):
            transitionToConnected(connection: connection, animated: animated)
        case .confirmDisconnect:
            transitionToConfirmDisconnect()
        case .processDisconnect:
            transitionToProccessDisconnect()
        case .disconnected:
            transitionToDisconnected(connection: connection)
        }
    }

    private func transitionToInitalization(connection: Connection, animated: Bool) {
        endActivationWebFlow()

        button.footerInteraction.isTapEnabled = true
        button.footerInteraction.onSelect = { [weak self] in
            self?.showAboutPage()
        }

        button.animator(for: .buttonState(buttonState(forConnectionStatus: connection.status, service: connection.connectingService), footerValue: FooterMessages.poweredBy.value)).preform(animated: animated)

        button.toggleInteraction.isTapEnabled = true
        button.toggleInteraction.isDragEnabled = true

        button.toggleInteraction.toggleTransition = {
            if self.credentialProvider.iftttServiceToken != nil {
                return .buttonState(.slideToConnectWithToken)
            } else {
                return .buttonState(.enterEmail(suggestedEmail: self.connectionConfiguration.suggestedUserEmail), footerValue: FooterMessages.enterEmail.value)
            }
        }

        button.toggleInteraction.onToggle = { [weak self] in
            if let token = self?.credentialProvider.iftttServiceToken {
                self?.transition(to: .identifyUser(.token(token)))
            }
        }

        button.emailInteraction.onConfirm = { [weak self] email in
            guard let self = self else {
                assertionFailure("It is expected that `self` is not nil here.")
                return
            }

            self.emailInteractionConfirmation(email: email)
        }
    }

    private func transitionToIdentifyUser(connection: Connection, lookupMethod: User.LookupMethod) {
        prepareActivationWebFlow(lookupMethod: lookupMethod)

        let timeout: TimeInterval = 3 // Network request timeout

        switch lookupMethod {
        case let .email(userEmail):
            button.animator(for: .buttonState(.verifyingEmail(message: "button.state.checking_account".localized), footerValue: FooterMessages.verifying(email: userEmail).value)).preform()

        case .token:
            button.animator(for: .buttonState(.accessingAccount(message: "button.state.accessing_existing_account".localized), footerValue: FooterMessages.poweredBy.value)).preform()
        }

        button.footerInteraction.isTapEnabled = true

        let progress = button.progressBar(timeout: timeout)
        progress.preform()

        let dataTask = connectionNetworkController.getConnectConfiguration(user: lookupMethod, waitUntil: 1, timeout: timeout) { [weak self] result in
            guard let self = self else {
                return
            }

            switch result {
            case .success(let user):
                if case .email(let email) = user.id, user.isExistingUser == false {

                    if self.accessAccountTask != nil {
                        // There is no account for this user
                        // Show a fake message that we are creating an account
                        // Then move to the first step of the service connection flow
                        self.button.animator(for: .buttonState(.createAccount(message: "button.state.creating_account".localized))).preform()
                    }

                    progress.resume(with: UISpringTimingParameters(dampingRatio: 1), duration: 1.5)
                    progress.onComplete { position in
                        if position == .end {
                            self.transition(to: .serviceAuthentication(connection.connectingService, newUserEmail: email))
                        }
                    }
                } else { // Existing IFTTT user
                    progress.resume(with: UISpringTimingParameters(dampingRatio: 1), duration: 0.25)
                    progress.onComplete { _ in
                        self.transition(to: .logInExistingUser(user.id))
                    }
                }

            case .failure(let error):
                self.transition(to: .failed(.networkError(error)))
            }
        }

        guard let accountLookupDataTask = dataTask else {
            assertionFailure("It is expected that you get a non nil data task.")
            return
        }

        accessAccountTask = AccessAccountTask(progressAnimation: progress, dataTask: accountLookupDataTask)

        button.emailInteraction.onConfirm = { [weak self] email in
            guard let self = self else {
                assertionFailure("It is expected that `self` is not nil here.")
                return
            }

            self.emailInteractionConfirmation(email: email)
        }
    }

    private func transitionToLogInExistingUser(userId: User.Id) {
        guard let connection = connection else {
            assertionFailure("It is expected and required that we have a non nil connection in this state.")
            return
        }

        openActivationURL(connection.activationURL(for: .login(userId), credentialProvider: credentialProvider, activationRedirect: connectionConfiguration.connectAuthorizationRedirectURL))
    }

    private func transitionToServiceAuthentication(service: Connection.Service, newUserEmail: String?) {
        guard let connection = connection else {
            assertionFailure("It is expected and required that we have a non nil connection in this state.")
            return
        }

        let footer: ConnectButtonController.FooterMessages

        if let newUserEmail = newUserEmail {
            footer = FooterMessages.verifying(email: newUserEmail)
        } else {
            footer = service == connection.primaryService ? FooterMessages.poweredBy : FooterMessages.connect(service, to: connection.primaryService)
        }

        button.footerInteraction.isTapEnabled = true
        button.animator(for: .buttonState(.continueToService(service: service.connectButtonService, message: "button.state.sign_in".localized(with: service.name)), footerValue: footer.value)).preform()

        let url = connection.activationURL(for: .serviceConnection(newUserEmail: newUserEmail), credentialProvider: connectionConfiguration.credentialProvider, activationRedirect: connectionConfiguration.connectAuthorizationRedirectURL)

        let timeout = 2.0
        button.progressBar(timeout: timeout).preform()

        let timer = Timer.scheduledTimer(withTimeInterval: timeout, repeats: false) { [weak self] timer in
            self?.openActivationURL(url)
            timer.invalidate()
        }

        button.stepInteraction.isTapEnabled = true
        button.stepInteraction.onSelect = { [weak self] in
            self?.openActivationURL(url)
            timer.invalidate()
        }
    }

    private func transitionToAuthenticationComplete() {
        button.animator(for: .buttonState(.connecting(message: "button.state.connecting".localized), footerValue: FooterMessages.poweredBy.value)).preform()

        let progressBar = button.progressBar(timeout: 2)
        progressBar.preform()
        progressBar.onComplete { _ in
            self.button.animator(for: .buttonState(.checkmark)).preform()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                self.transition(to: .connected(animated: true))
            }
        }
    }

    private func transitionToFailed(error: Error) {
        delegate?.connectButtonController(self, didFinishActivationWithResult: .failure(.networkError(.genericError(error))))
        transition(to: .initial(animated: false))
    }

    private func transitionToCanceled(connection: Connection) {
        delegate?.connectButtonController(self, didFinishActivationWithResult: .failure(.canceled))
        transitionToInitalization(connection: connection, animated: true)
    }

    private func transitionToConnected(connection: Connection, animated: Bool) {
        button.animator(for: .buttonState(buttonState(forConnectionStatus: .enabled, service: connection.connectingService), footerValue: FooterMessages.manage.value)).preform(animated: animated)

        button.footerInteraction.isTapEnabled = true

        // Connection was changed to this state, not initialized with it, so let the delegate know
        appletChangedStatus(isOn: true)

        // Toggle from here goes to disconnection confirmation
        // When the user taps the switch, they are asked to confirm disconnection by dragging the switch into the off position
        button.toggleInteraction.isTapEnabled = true

        button.toggleInteraction.toggleTransition = {
            return .buttonState(.slideToDisconnect(message: "button.state.disconnect".localized),
                                footerValue: .none)
        }

        button.toggleInteraction.onToggle = { [weak self] in
            self?.transition(to: .confirmDisconnect)
        }
    }

    private func transitionToConfirmDisconnect() {
       let timer = Timer.scheduledTimer(withTimeInterval: 10, repeats: false) { [weak self] timer in
            // Revert state if user doesn't follow through
            self?.transition(to: .connected(animated: false))
            timer.invalidate()
        }
        
        // The user must slide to deactivate the Connection
        button.toggleInteraction = .init(isTapEnabled: false,
                                         isDragEnabled: true,
                                         resistance: .heavy,
                                         toggleTransition: {
                                            .buttonState(.disconnecting(message: "button.state.disconnecting".localized),
                                                                          footerValue: .none) },
                                         onToggle: { [weak self] in
                                            self?.transition(to: .processDisconnect)
                                            timer.invalidate() })
    }

    private func transitionToProccessDisconnect() {
        guard let connection = connection else {
            assertionFailure("It is expected and required that we have a non nil connection in this state.")
            return
        }

        let timeout: TimeInterval = 3 // Network request timeout

        let progress = button.progressBar(timeout: timeout)
        progress.preform()

        let request = Connection.Request.disconnectConnection(with: connection.id, credentialProvider: credentialProvider)
        connectionNetworkController.start(urlRequest: request.urlRequest, waitUntil: 1, timeout: timeout) { response in
            progress.resume(with: UISpringTimingParameters(dampingRatio: 1), duration: 0.25)
            progress.onComplete { _ in
                switch response.result {
                case .success:
                    self.transition(to: .disconnected)
                case .failure(let error):
                    self.delegate?.connectButtonController(self, didFinishDeactivationWithResult: .failure(.networkError(error)))
                    self.transition(to: .connected(animated: true))
                }
            }
        }
    }

    private func transitionToDisconnected(connection: Connection) {
        appletChangedStatus(isOn: false)

        button.animator(for: .buttonState(.disconnected(service: connection.connectingService.connectButtonService, message: "button.state.disconnected".localized))).preform()
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.transition(to: .initial(animated: true))
        }
    }

    private var emailFooterTimer: Timer?

    private func emailInteractionConfirmation(email: String) {
        emailFooterTimer?.invalidate()
        emailFooterTimer = nil

        if email.isValidEmail {
            self.transition(to: .identifyUser(.email(email)))
        } else {
            self.delegate?.connectButtonController(self, didRecieveInvalidEmail: email)
            self.button.animator(for: .footerValue(FooterMessages.emailInvalid.value)).preform()
            self.button.performInvalidEmailAnimation()

            emailFooterTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { [weak self] timer in
                self?.button.animator(for: .footerValue(FooterMessages.enterEmail.value)).preform()
                timer.invalidate()
            }
        }
    }
}


// MARK: - Convenience

@available(iOS 10.0, *)
private extension Connection.Service {
    var connectButtonService: ConnectButton.Service {
        return ConnectButton.Service(iconURL: templateIconURL, brandColor: brandColor)
    }
}
