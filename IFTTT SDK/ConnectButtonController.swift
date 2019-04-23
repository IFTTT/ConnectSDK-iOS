//
//  ConnectButtonController.swift
//  IFTTT SDK
//
//  Created by Jon Chmura on 9/19/18.
//  Copyright © 2018 IFTTT. All rights reserved.
//

import UIKit
import SafariServices

/// Bundles values when a Connection is activated
public struct ConnectionActivation {
    
    /// The IFTTT service-level user token for your service.
    public let userToken: String?
    
    /// The Connection that was activated
    public let connection: Connection
}

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
    func connectButtonController(_ connectButtonController: ConnectButtonController,
                                 didFinishActivationWithResult result: Result<ConnectionActivation, ConnectButtonControllerError>)

    /// Connection deactivation is finished.
    ///
    /// On success, the controller transitions the button to its deactivated initial state.
    ///
    /// On failure, the controller will reset the Connection to the connected state but will not show any messaging. The user attempted to deactivate the Connection but something unexpected went wrong, likely a network failure. It is up to you to do this. This should be rare but should be handled.
    ///
    /// - Parameters:
    ///   - connectButtonController: The `ConnectButtonController` controller that is sending the message.
    ///   - result: A result of the connection deactivation request.
    func connectButtonController(_ connectButtonController: ConnectButtonController,
                                 didFinishDeactivationWithResult result: Result<Connection, ConnectButtonControllerError>)
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

    /// The current `User`
    /// This is set during the `identifyUser` step. It is required that we have this information for later steps in the flow.
    private var user: User?
    
    private func handleActivationFinished(userToken: String?) {
        connection?.status = .enabled
        if let connection = connection {
            let activation = ConnectionActivation(userToken: userToken,
                                                  connection: connection)
            delegate?.connectButtonController(self, didFinishActivationWithResult: .success(activation))
        }
    }
    
    private func handleActivationFailed(error: ConnectButtonControllerError) {
        delegate?.connectButtonController(self, didFinishActivationWithResult: .failure(error))
    }
    
    private func handleDeactivationFinished() {
        connection?.status = .disabled
        if let connection = connection {
            delegate?.connectButtonController(self, didFinishDeactivationWithResult: .success(connection))
        }
    }
    
    private func handleDeactivationFailed(error: ConnectButtonControllerError) {
        delegate?.connectButtonController(self, didFinishDeactivationWithResult: .failure(error))
    }

    private var credentialProvider: CredentialProvider {
        return connectionConfiguration.credentialProvider
    }

    /// An `ConnectButtonControllerDelegate` object that will recieved messages about events that happen on the `ConnectButtonController`.
    public private(set) weak var delegate: ConnectButtonControllerDelegate?

    private let connectionConfiguration: ConnectionConfiguration
    private let connectionActivationFlow: ConnectionActivationFlow
    private let connectionNetworkController = ConnectionNetworkController()
    private let serviceIconNetworkController = ServiceIconsNetworkController()
    private let reachability = Reachability()

    /// Creates a new `ConnectButtonController`.
    ///
    /// - Parameters:
    ///   - connectButton: The `ConnectButton` that the controller is handling interaction for.
    ///   - connectionConfiguration: The `ConnectionConfiguration` with information for authenticating a `Connection`.
    ///   - delegate: A `ConnectInteractionDelegate` to respond to various events that happen on the controller.
    public init(connectButton: ConnectButton, connectionConfiguration: ConnectionConfiguration, delegate: ConnectButtonControllerDelegate) {
        self.button = connectButton
        self.connectionConfiguration = connectionConfiguration
        self.connectionActivationFlow = ConnectionActivationFlow(connectionId: connectionConfiguration.connectionId,
                                                                 credentialProvider: connectionConfiguration.credentialProvider,
                                                                 activationRedirect: connectionConfiguration.connectAuthorizationRedirectURL)
        self.connection = connectionConfiguration.connection
        self.delegate = delegate
        setupConnection(for: connection, animated: false)
        beginRedirectObserving()
    }

    private func setupConnection(for connection: Connection?, animated: Bool) {
        button.minimumFooterLabelHeight = FooterMessages.estimatedMaximumTextHeight
       
        guard let connection = connection else {
            fetchConnection(for: connectionConfiguration.connectionId)
            return
        }

        button.imageViewNetworkController = serviceIconNetworkController
        serviceIconNetworkController.prefetchImages(for: connection)

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
    
    private var connectionFetchingDataTask: URLSessionDataTask?
    
    private func fetchConnection(for id: String, numberOfRetries: Int = 3, retryCount: Int = 0) {
        button.animator(for: .buttonState(.loading(message: "button.state.loading".localized))).perform(animated: true)
        button.animator(for: .footerValue(FooterMessages.worksWithIFTTT.value)).perform(animated: false)
        connectionFetchingDataTask?.cancel()
        connectionFetchingDataTask = nil

        connectionFetchingDataTask = connectionNetworkController.start(request: .fetchConnection(for: id, credentialProvider: credentialProvider)) { [weak self] response in
            guard let self = self else { return }
            
            switch response.result {
            case .success(let connection):
                self.connection = connection
                self.setupConnection(for: connection, animated: true)

            case .failure:
                if retryCount < numberOfRetries {
                    let count = retryCount + 1
                    DispatchQueue.main.asyncAfter(deadline: .now() + self.exponentialBackoffTiming(for: count)) {
                        self.fetchConnection(for: id, retryCount: count)
                    }
                } else {
                    let footer = ConnectButtonController.FooterMessages.loadingFailed.value
                    self.button.animator(for: .buttonState(.loadingFailed, footerValue: footer)).perform(animated: true)
                    self.button.footerInteraction.isTapEnabled = true
                    self.button.footerInteraction.onSelect = { [weak self] in
                        self?.fetchConnection(for: id)
                        self?.reachability?.stopNotifier()
                    }
                    self.setupReachabilityForConnectionLoading(id: id)
                }
            }
        }
    }
    
    private func setupReachabilityForConnectionLoading(id: String) {
        reachability?.whenReachable = { [weak self] _ in
            guard let self = self else {
                return
            }
            
            self.fetchConnection(for: id)
            self.reachability?.stopNotifier()
        }
        
        do {
            try reachability?.startNotifier()
        } catch {
            assertionFailure("Reachability was unable to start notifications due to error: \(error).")
        }
    }
    
    private func exponentialBackoffTiming(for retryCount: Int) -> DispatchTimeInterval {
        let seconds = Int(pow(2, Double(retryCount)))
        return .seconds(seconds)
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

    /// A comprehensive list of copy for the Connect Button's footer
    ///
    /// - worksWithIFTTT: Default message used for most button states
    /// - enterEmail: Message for the enter email step
    /// - emailInvalid: Message when the entered email is invalid
    enum FooterMessages {
        case worksWithIFTTT
        case enterEmail
        case emailInvalid
        case loadingFailed

        private struct Constants {
            static let textColor = UIColor(white: 0.68, alpha: 1)
            
            static let errorTextColor = UIColor.red
            
            static var footnoteFont: UIFont {
                return .footnote(weight: .demiBold)
            }
            static var iftttWordmarkFont: UIFont {
                return .footnote(weight: .heavy)
            }
        }

        /// Our best guess of the maximum height of the footer label
        fileprivate static var estimatedMaximumTextHeight: CGFloat {
            // We are estimating that the text will never exceed 2 lines (plus some line spacing)
            return 1.1 * Constants.footnoteFont.lineHeight
        }

        private var iftttWordmark: NSAttributedString {
            return NSAttributedString(string: "IFTTT",
                                      attributes: [.font : Constants.iftttWordmarkFont,
                                                   .foregroundColor : Constants.textColor])
        }

        var value: ConnectButton.LabelValue {
            return .attributed(attributedString)
        }
        
        var isErrorMessage: Bool {
            switch self {
            case .worksWithIFTTT, .enterEmail:
                return false
            case .emailInvalid, .loadingFailed:
                return true
            }
        }

        private var textColor: UIColor {
            if isErrorMessage {
                return Constants.errorTextColor
            } else {
                return Constants.textColor
            }
        }
        
        var attributedString: NSAttributedString {

            switch self {
            case .worksWithIFTTT:
                let text = NSMutableAttributedString(string: "button.footer.works_with".localized,
                                                     attributes: [.font : Constants.footnoteFont,
                                                                  .foregroundColor : textColor])
                text.append(iftttWordmark)
                return text
                
            case .enterEmail:
                let text = NSMutableAttributedString(string: "button.footer.email.prefix".localized,
                                                     attributes: [.font : Constants.footnoteFont,
                                                                  .foregroundColor : textColor])
                text.append(iftttWordmark)
                text.append(NSAttributedString(string: " ")) // Adds a space before the underline starts
                text.append(NSAttributedString(string: "button.footer.email.postfix".localized,
                                               attributes: [.font : Constants.footnoteFont,
                                                            .foregroundColor : textColor,
                                                            .underlineStyle : NSUnderlineStyle.single.rawValue]))
                return text

            case .emailInvalid:
                let text = "button.footer.email.invalid".localized
                return NSAttributedString(string: text, attributes: [.font : Constants.footnoteFont,
                                                                     .foregroundColor : textColor])

            case .loadingFailed:
                let text = NSMutableAttributedString(string: "button.footer.loading.failed.prefix".localized, attributes: [.font : Constants.footnoteFont, .foregroundColor : textColor])
                
                text.append(NSAttributedString(string: " ")) // Adds a space before the underline starts
                text.append(NSAttributedString(string: "button.footer.loading.failed.postfix".localized,
                                               attributes: [.font : Constants.footnoteFont,
                                                            .foregroundColor : textColor,
                                                            .underlineStyle : NSUnderlineStyle.single.rawValue]))
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
            static let userToken = "user_token"
            static let error = "error"
            static let errorType = "error_type"
            static let errorTypeAccountCreation = "account_creation"
        }

        /// Authorization redirect encodes some information about what comes next in the flow
        ///
        /// - serviceConnection: In the next step, authorize a service.
        /// - complete: The Connection is complete. If the user token was present in the redirect, it is returned here. This is optional to allow future flexibility.
        /// - failed: An error occurred on web, aborting the flow.
        enum Outcome {
            case serviceAuthorization(id: String)
            case complete(userToken: String?)
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
                let userToken = queryItems.first(where: { $0.name == QueryItems.userToken })?.value
                onRedirect?(.complete(userToken: userToken))

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

    private let redirectObserving = RedirectObserving()

    /// Starts monitoring for connection flow redirects
    private func beginRedirectObserving() {
        redirectObserving.onRedirect = { [weak self] outcome in
            self?.handleRedirect(outcome)
        }
    }
    
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

                if let service = connection.services.first(where: { $0.id == id }), let user = user {
                    // If service connection comes after a redirect we must have already completed user log in or account creation
                    // Therefore newUserEmail is always nil here
                    return .serviceAuthentication(service, user: user)
                } else {
                    // For some reason, the service ID we received from web doesn't match the connection
                    // If this ever happens, it is due to a bug on web
                    return .failed(.unknownRedirect)
                }
            case .complete(let userToken):
                return .authenticationComplete(userToken: userToken)
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
        safariDelegate = SafariDelegate { [weak self] in
            self?.handleCancelation(lookupMethod: lookupMethod)
        }
    }

    /// Once activation is finished or canceled, tear down redirect and cancelation observing
    private func endActivationWebFlow() {
        safariDelegate = nil
    }



    // MARK: - Connection activation & deactivation

    /// Defines the `Connection` authorization state machine
    ///
    /// - initial: The `Connection` is in the initial state (not authorized)
    /// - appHandoff: Links to the IFTTT app to complete the connection flow
    /// - enterEmail: If we don't yet know the user, show the email field
    /// - identifyUser: We will have an email address or an IFTTT service token. Use this information to determine if they are already an IFTTT user. Obviously they are if we have an IFTTT token, but we still need to get their username.
    /// - logInExistingUser: If we have a user token, ensure the user is logged in to Safari.
    /// - serviceAuthentication: Authorize one of this `Connection`s services. Passing the service to connect and the current user.
    /// - authenticationComplete: Connection activation was successful. This always originates from the authorization redirect. Passes the user token if it was included in the redirect.
    /// - failed: The `Connection` could not be authorized due to some error.
    /// - canceled: The `Connection` authorization was canceled.
    /// - connected: The `Connection` was successfully authorized.
    /// - confirmDisconnect: The "Slide to disconnect" state, asking for the user's confirmation to disable the `Connection`.
    /// - processDisconnect: Disable the `Connection`.
    /// - disconnected: The `Connection` was disabled.
    enum ActivationStep {
        case initial(animated: Bool)
        case appHandoff
        case enterEmail
        case identifyUser(User.LookupMethod)
        case logInExistingUser(User)
        case serviceAuthentication(Connection.Service, user: User)
        case authenticationComplete(userToken: String?)
        case failed(ConnectButtonControllerError)
        case canceled
        case connected(animated: Bool)
        case confirmDisconnect
        case processDisconnect
        case disconnected
    }

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
        case .appHandoff:
            transitionToAppHandoff()
        case .enterEmail:
            self.transition(to: .initial(animated: false))
            self.button.animator(for: .buttonState(.enterEmail(service: connection.connectingService.connectButtonService, suggestedEmail: self.connectionConfiguration.suggestedUserEmail), footerValue: FooterMessages.enterEmail.value)).perform()
        case .identifyUser(let lookupMethod):
            transitionToIdentifyUser(connection: connection, lookupMethod: lookupMethod)
        case .logInExistingUser(let user):
            transitionToLogInExistingUser(connection: connection, user: user)
        case .serviceAuthentication(let service, let user):
            transitionToServiceAuthentication(connection: connection, service: service, user: user)
        case .authenticationComplete(let userToken):
            handleActivationFinished(userToken: userToken)
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
            handleDeactivationFinished()
            transitionToDisconnected(connection: connection)
        }
    }
    
    private func transitionToInitalization(connection: Connection, animated: Bool) {
        endActivationWebFlow()

        button.footerInteraction.isTapEnabled = true
        button.footerInteraction.onSelect = { [weak self] in
            self?.showAboutPage()
        }

        let initialButtonState = ConnectButton.Transition.buttonState(buttonState(forConnectionStatus: connection.status,
                                                                                  service: connection.connectingService),
                                                                      footerValue: FooterMessages.worksWithIFTTT.value)
        button.animator(for: initialButtonState).perform(animated: animated)

        button.toggleInteraction.isTapEnabled = true
        button.toggleInteraction.isDragEnabled = true

        button.toggleInteraction.toggleTransition = { [weak self] in
            guard let self = self else {
                return initialButtonState
            }
            if self.connectionActivationFlow.isAppHandoffAvailable || self.credentialProvider.iftttServiceToken != nil {
                return .buttonState(.slideToConnect(message: "button.state.verifying".localized))
            } else {
                return .buttonState(.enterEmail(service: connection.connectingService.connectButtonService, suggestedEmail: self.connectionConfiguration.suggestedUserEmail), footerValue: FooterMessages.enterEmail.value, duration: 1.0)
            }
        }

        button.toggleInteraction.onToggle = { [weak self] in
            guard let self = self else { return }
            if self.connectionActivationFlow.isAppHandoffAvailable {
                self.transition(to: .appHandoff)
            } else if let token = self.credentialProvider.iftttServiceToken {
                self.transition(to: .identifyUser(.token(token)))
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

    private func transitionToAppHandoff() {
        let progress = button.showProgress(duration: 1)
        progress.addCompletion { _ in
            self.connectionActivationFlow.performAppHandoff()
        }
        progress.startAnimation()
        
        // Resets the button state after a app handoff
        // Should the user return without completing the flow, they can just start over
        // We will handle initial -> complete transition via the redirect
        var token: Any?
        token = NotificationCenter.default.addObserver(forName: UIApplication.didEnterBackgroundNotification,
                                               object: nil,
                                               queue: .main) { _ in
                                                self.transition(to: .initial(animated: false))
                                                if let token = token {
                                                    // This is one-time use. Remove it immediately.
                                                    NotificationCenter.default.removeObserver(token)
                                                }
        }
    }
    
    private func transitionToIdentifyUser(connection: Connection, lookupMethod: User.LookupMethod) {
        prepareActivationWebFlow(lookupMethod: lookupMethod)

        let state: ConnectButton.AnimationState
        switch lookupMethod {
        case .email:
            state = .verifyingEmail(message: "button.state.verifying".localized)
        case .token:
            state = .accessingAccount(message: "button.state.verifying".localized)
        }
        button.animator(for: .buttonState(state,
                                          footerValue: FooterMessages.worksWithIFTTT.value)).perform()

        button.footerInteraction.isTapEnabled = true

        // Pause at halfway here since we may follow up with the user account creation message
        let progress = ProgressBarController(progressBar: button, pauseAt: 0.5)
        progress.begin()
        
        let dataTask = connectionNetworkController.getConnectConfiguration(user: lookupMethod) { [weak self] result in
            guard let self = self else {
                return
            }
            switch result {
            case .success(let user):
                self.user = user
                
                if case .email = user.id { // We know the user's email but don't have a token
                    if user.isExistingUser {
                        // This is an existing IFTTT user but we don't have a token
                        // Send on to service authentication, web will take care of getting the user signed in
                        progress.finish {
                            self.transition(to: .serviceAuthentication(connection.connectingService, user: user))
                        }
                    } else {
                        // There is no account for this user
                        // Show a fake message that we are creating an account
                        // Then move to the first step of the service connection flow
                        let minimumDuration = 0.5
                        let timeTillMinimumDuration = minimumDuration - progress.currentDuration
                        DispatchQueue.main.asyncAfter(deadline: .now() + timeTillMinimumDuration) {
                            self.button.animator(for: .buttonState(.createAccount(message: "button.state.creating_account".localized))).perform()
                        }
                        
                        progress.finish {
                            self.transition(to: .serviceAuthentication(connection.connectingService, user: user))
                        }
                    }
                } else { // Existing IFTTT user (with a token)
                    progress.finish {
                        self.transition(to: .logInExistingUser(user))
                    }
                }

            case .failure(let error):
                self.transition(to: .failed(.networkError(error)))
            }
        }
        dataTask?.resume()

        button.emailInteraction.onConfirm = { [weak self] email in
            guard let self = self else {
                assertionFailure("It is expected that `self` is not nil here.")
                return
            }

            self.emailInteractionConfirmation(email: email)
        }
    }

    private func transitionToLogInExistingUser(connection: Connection, user: User) {
        let url = connectionActivationFlow.loginUrl(userId: user.id)
        openActivationURL(url)
    }

    private func transitionToServiceAuthentication(connection: Connection, service: Connection.Service, user: User) {
        button.footerInteraction.isTapEnabled = true
        button.animator(for: .buttonState(.continueToService(service: service.connectButtonService,
                                                             message: "button.state.sign_in".localized(with: service.name)),
                                          footerValue: FooterMessages.worksWithIFTTT.value)).perform()

        let url = connectionActivationFlow.serviceConnectionUrl(user: user)

        let timeout = 2.0
        button.showProgress(duration: timeout).startAnimation()
        
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
        button.animator(for: .buttonState(.connecting(message: "button.state.connecting".localized),
                                          footerValue: FooterMessages.worksWithIFTTT.value)).perform()

        let progress = button.showProgress(duration: 2)
        progress.perform()
        progress.addCompletion { _ in
            self.button.animator(for: .buttonState(.checkmark)).perform()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                self.transition(to: .connected(animated: true))
            }
        }
    }

    private func transitionToFailed(error: Error) {
        handleActivationFailed(error: .networkError(.genericError(error)))
        transition(to: .initial(animated: false))
    }

    private func transitionToCanceled(connection: Connection) {
        handleActivationFailed(error: .canceled)
        transitionToInitalization(connection: connection, animated: true)
    }

    private func transitionToConnected(connection: Connection, animated: Bool) {
        button.animator(for: .buttonState(buttonState(forConnectionStatus: .enabled, service: connection.connectingService), footerValue: FooterMessages.worksWithIFTTT.value)).perform(animated: animated)

        button.footerInteraction.isTapEnabled = true

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

        let progress = ProgressBarController(progressBar: button)
        progress.begin()

        let request = Connection.Request.disconnectConnection(with: connection.id, credentialProvider: credentialProvider)
        connectionNetworkController.start(urlRequest: request.urlRequest) { response in
            progress.finish {
                switch response.result {
                case .success:
                    self.transition(to: .disconnected)
                case .failure(let error):
                    self.handleDeactivationFailed(error: .networkError(error))
                    self.transition(to: .connected(animated: true))
                }
            }
        }
    }

    private func transitionToDisconnected(connection: Connection) {
        button.animator(for: .buttonState(.disconnected(message: "button.state.disconnected".localized))).perform()
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
            self.button.animator(for: .footerValue(FooterMessages.emailInvalid.value)).perform()
            self.button.performInvalidEmailAnimation()

            emailFooterTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { [weak self] timer in
                self?.button.animator(for: .footerValue(FooterMessages.enterEmail.value)).perform()
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

@available(iOS 10.0, *)
private extension UIViewPropertyAnimator {
    func perform(animated: Bool = true) {
        if animated {
            startAnimation()
        } else {
            startAnimation()
            stopAnimation(false)
            finishAnimation(at: .end)
        }
    }
}
