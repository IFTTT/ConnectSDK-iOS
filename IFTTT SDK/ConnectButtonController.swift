//
//  ConnectButtonController.swift
//  IFTTT SDK
//
//  Copyright © 2019 IFTTT. All rights reserved.
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
    case networkError(ConnectionNetworkError)

    /// A user cancelled the service authentication with the `Connection`. This happens when the user cancels from the sign in process on an authorization page in a safari view controller.
    case canceled
    
    /// A user cancelled the configuration of the connection in the IFTTT app.
    case userCancelledConfiguration

    /// Redirect parameters did not match what we expected. This should never happen. Verify you are using the latest SDK.
    case unknownRedirect

    /// Response parameters did not match what we expected. This should never happen. Verify you are using the latest SDK.
    case unknownResponse

    /// For some reason the `Connection` used by this controller has gone nil or could not be retrieved. This should never happen.
    case unableToGetConnection
    
    /// For some reason we could not redirect to the IFTTT app. This should never happen since we check if the app is installed first.
    case iftttAppRedirectFailed
}

/// Defines the communication between ConnectButtonController and your app. It is required to implement this protocol.
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
    
    /// This is required as of iOS 13 to go through an authentication flow as a part of connection activation. This flow is shown if the user does not have the IFTTT app installed.
    ///
    /// - Returns: A `UIWindow` to show the web authentication flow on.
    @available(iOS 13.0, *)
    func webAuthenticationPresentationAnchor() -> UIWindow
}

/// A controller that handles the `ConnectButton` when authenticating a `Connection`. It is mandatory that you interact with the ConnectButton only through this controller.
public class ConnectButtonController {

    /// The connect button in this interaction
    public let button: ConnectButton

    /// The `Connection` the controller is handling. The controller may change the `Connection.Status` of the `Connection`.
    public private(set) var connection: Connection?
    
    /// Controls whether or not analytics events should be sent from the connect button.
    public static var analyticsEnabled: Bool {
        set {
            Analytics.shared.enabled = newValue
        }
        get {
            return Analytics.shared.enabled
        }
    }

    /// The current `User`
    /// This is set during the `identifyUser` step. It is required that we have this information for later steps in the flow.
    private var user: User?
    
    private func handleActivationFinished(userToken: String?) {
        var state: AnalyticsState? = nil
        if let status = connection?.status {
            state = (status == .initial) ? .Created : .Enabled
        }
        connection?.status = .enabled
        
        if let connection = connection {
            fetchConnection(for: connection.id, updateConnectButton: false, isAuthenticated: userToken != nil)
            Analytics.shared.track(.StateChange,
                                   object: connection,
                                   state: state)
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
            ConnectionsMonitor.shared.update(with: connection)
            delegate?.connectButtonController(self, didFinishDeactivationWithResult: .success(connection))
        }
    }
    
    private func handleDeactivationFailed(error: ConnectButtonControllerError) {
        delegate?.connectButtonController(self, didFinishDeactivationWithResult: .failure(error))
    }

    private var credentialProvider: ConnectionCredentialProvider {
        return connectionConfiguration.credentialProvider
    }

    /// An `ConnectButtonControllerDelegate` object that will recieved messages about events that happen on the `ConnectButtonController`.
    public private(set) weak var delegate: ConnectButtonControllerDelegate?

    private let connectionConfiguration: ConnectionConfiguration
    private let connectionHandoffFlow: ConnectionHandoffFlow
    private let connectionNetworkController = ConnectionNetworkController()
    private let serviceIconNetworkController = ServiceIconsNetworkController()
    private let reachability = Reachability()
    private let connectionVerificationSession: ConnectionVerificationSession

    /// Creates a new `ConnectButtonController`.
    ///
    /// - Parameters:
    ///   - connectButton: The `ConnectButton` that the controller is handling interaction for.
    ///   - connectionConfiguration: The `ConnectionConfiguration` with information for authenticating a `Connection`.
    ///   - delegate: A `ConnectInteractionDelegate` to respond to various events that happen on the controller.
    public init(connectButton: ConnectButton, connectionConfiguration: ConnectionConfiguration, delegate: ConnectButtonControllerDelegate) {
        self.button = connectButton
        self.connectionConfiguration = connectionConfiguration
        self.connectionHandoffFlow = ConnectionHandoffFlow(connectionId: connectionConfiguration.connectionId,
                                                                 credentialProvider: connectionConfiguration.credentialProvider,
                                                                 activationRedirect: connectionConfiguration.redirectURL)
        self.connection = connectionConfiguration.connection
        self.delegate = delegate
        self.connectionVerificationSession = ConnectionVerificationSession()
        
        self.button.analyticsDelegate = self
        
        setupConnection(for: connection, animated: false)
        setupVerification()
    }
    
    private func setupVerification() {
        connectionVerificationSession.completionHandler =  { [weak self] (outcome) in
            self?.handleOutcome(outcome)
        }
    }
    
    private func handleOutcome(_ outcome: ConnectionVerificationSession.Outcome) {
        connectionVerificationSession.dismiss { [weak self] in
            // Determine the next step based on the redirect result
            let nextStep: ActivationStep = {
                switch outcome {
                case .error(let error):
                    return .failed(error)
                    
                case .token(let userToken):
                    return .activationComplete(userToken: userToken)
                    
                case .email:
                    return .enterEmail
                }
            }()
            self?.transition(to: nextStep)
        }
    }

    private func setupConnection(for connection: Connection?, animated: Bool) {
        let emailValidator = EmailValidator()

        if !ConnectionDeeplinkAction.isIftttAppAvailable && !emailValidator.validate(with: connectionConfiguration.suggestedUserEmail) {
            assertionFailure("Unable to display connect button. This will only occur if the app is not installed and the email address is invalid.")
            button.isHidden = true
            return
        }
        
        button.minimumFooterLabelHeight = FooterMessages.estimatedMaximumTextHeight
       
        guard let connection = connection else {
            fetchConnection(for: connectionConfiguration.connectionId)
            return
        }
        
        ConnectionsMonitor.shared.update(with: connection)
        Analytics.shared.track(.Impression,
                               location: .connectButtonImpression,
                               object: connection)

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
    
    private func fetchConnection(for id: String,
                                 numberOfRetries: Int = 3,
                                 retryCount: Int = 0,
                                 updateConnectButton: Bool = true,
                                 isAuthenticated: Bool = false) {
        button.animator(for: .buttonState(.loading(message: "button.state.loading".localized))).perform(animated: true)
        button.animator(for: .footerValue(FooterMessages.worksWithIFTTT.value)).perform(animated: false)
        connectionFetchingDataTask?.cancel()
        connectionFetchingDataTask = nil

        connectionFetchingDataTask = connectionNetworkController.start(request: .fetchConnection(for: id, credentialProvider: credentialProvider)) { [weak self] response in
            guard let self = self else { return }
            
            switch response.result {
            case .success(let connection):
                self.connection = connection
                if isAuthenticated {
                    ConnectionsMonitor.shared.update(with: connection)
                }
                if updateConnectButton {
                    self.setupConnection(for: connection, animated: true)
                }

            case .failure:
                if retryCount < numberOfRetries {
                    let count = retryCount + 1
                    DispatchQueue.main.asyncAfter(deadline: .now() + self.exponentialBackoffTiming(for: count)) {
                        self.fetchConnection(for: id, retryCount: count)
                    }
                } else {
                    if updateConnectButton {
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

    private func buttonState(forConnectionStatus status: Connection.Status, service: Connection.Service, shouldAnimateKnob: Bool = true) -> ConnectButton.AnimationState {
        switch status {
        case .initial, .disabled, .unknown:
            return .connect(service: service.connectButtonService,
                            message: "button.state.connect".localized(with: service.shortName))
        case .enabled:
            return .connected(service: service.connectButtonService,
                              message: "button.state.connected".localized,
                              shouldAnimateKnob: shouldAnimateKnob)
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
        
        Analytics.shared.track(.Click,
                               location: Location(type: "connect_button", identifier: nil),
                               sourceLocation: nil,
                               object: AnalyticsObject.worksWithIFTTT,
                               state: nil)
        
        let aboutViewController = AboutViewController(connection: connection, activationFlow: connectionHandoffFlow)
        present(aboutViewController)
    }

    /// A comprehensive list of copy for the Connect Button's footer
    ///
    /// - worksWithIFTTT: Default message used for most button states
    /// - enterEmail: Message for the enter email step
    /// - emailInvalid: Message when the entered email is invalid
    private enum FooterMessages {
        case worksWithIFTTT
        case enterEmail
        case emailInvalid
        case creatingAccount(email: String)
        case loadingFailed

        private struct Constants {
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
            // We are estimating that the text will never exceed 1 lines (plus some line spacing)
            return 1.1 * Constants.footnoteFont.lineHeight
        }

        private var iftttWordmark: NSAttributedString {
            return NSAttributedString(string: "IFTTT",
                                      attributes: [.font : Constants.iftttWordmarkFont])
        }

        var value: ConnectButton.LabelValue {
            return .attributed(attributedString)
        }
        
        var attributedString: NSAttributedString {

            switch self {
            case .worksWithIFTTT:
                let text = NSMutableAttributedString(string: "button.footer.works_with".localized,
                                                     attributes: [.font : Constants.footnoteFont])
                text.append(iftttWordmark)
                return text
                
            case .enterEmail:
                let text = NSMutableAttributedString(string: "button.footer.email.prefix".localized,
                                                     attributes: [.font : Constants.footnoteFont])
                text.append(iftttWordmark)
                text.append(NSAttributedString(string: " ")) // Adds a space before the underline starts
                text.append(NSAttributedString(string: "button.footer.email.postfix".localized,
                                               attributes: [.font : Constants.footnoteFont,
                                                            .underlineStyle : NSUnderlineStyle.single.rawValue]))
                return text

            case .emailInvalid:
                let text = "button.footer.email.invalid".localized
                return NSAttributedString(string: text,
                                          attributes: [.font : Constants.footnoteFont,
                                                       .foregroundColor : Constants.errorTextColor])
                
            case let .creatingAccount(email):
                let text = NSMutableAttributedString(string: "button.footer.accountCreation.prefix".localized,
                                                     attributes: [.font : Constants.footnoteFont])
                text.append(iftttWordmark)
                text.append(NSAttributedString(string: " "))
                text.append(NSMutableAttributedString(string: "button.footer.accountCreation.postfix".localized(with: email),
                                                      attributes: [.font : Constants.footnoteFont]))
                
                return text
                
            case .loadingFailed:
                let text = NSMutableAttributedString(string: "button.footer.loading.failed.prefix".localized,
                                                     attributes: [.font : Constants.footnoteFont,
                                                                  .foregroundColor : Constants.errorTextColor])
                
                text.append(NSAttributedString(string: " ")) // Adds a space before the underline starts
                text.append(NSAttributedString(string: "button.footer.loading.failed.postfix".localized,
                                               attributes: [.font : Constants.footnoteFont,
                                                            .foregroundColor : Constants.errorTextColor,
                                                            .underlineStyle : NSUnderlineStyle.single.rawValue]))
                return text
            }
        }
    }

    // MARK: - Connection activation & deactivation

    /// Defines the `Connection` authorization state machine
    ///
    /// - initial: The `Connection` is in the initial state (not authorized)
    /// - appHandoff: Links to the IFTTT app to complete the connection flow
    /// - enterEmail: If we don't yet know the user, show the email field
    /// - identifyUser: We will have an email address or an IFTTT service token. Use this information to determine if they are already an IFTTT user. Obviously they are if we have an IFTTT token, but we still need to get their username.
    /// - activateConnection: Go to the web or the IFTTT app to activate this Connection. RedirectImmediately will cause the button to skip showing the going to service progress bar.
    /// - activationComplete: Connection activation was successful. This always originates from a redirect. Passes the user token if it was included in the redirect.
    /// - failed: The `Connection` could not be authorized due to some error.
    /// - canceled: The `Connection` authorization was canceled.
    /// - connected: The `Connection` was successfully authorized.
    /// - processDisconnect: Disable the `Connection`.
    /// - disconnected: The `Connection` was disabled.
    enum ActivationStep {
        case initial(animated: Bool)
        case appHandoff(url: URL, redirectImmediately: Bool)
        case enterEmail
        case identifyUser(User.LookupMethod)
        case activateConnection(user: User, redirectImmediately: Bool)
        case activationComplete(userToken: String?)
        case failed(ConnectButtonControllerError)
        case canceled
        case connected(animated: Bool)
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
        button.footerInteraction.isTapEnabled = false // Don't clear the select block

        switch step {
        case .initial(let animated):
            transitionToInitalization(connection: connection, animated: animated)
        case .appHandoff(let url, let redirectImmediately):
            transitionToAppHandoff(url: url, redirectImmediately: redirectImmediately)
        case .enterEmail:
            self.transition(to: .initial(animated: false))
            self.button.animator(for: .buttonState(.enterEmail(service: connection.connectingService.connectButtonService, suggestedEmail: self.connectionConfiguration.suggestedUserEmail), footerValue: FooterMessages.enterEmail.value)).perform()
        case .identifyUser(let lookupMethod):
            transitionToIdentifyUser(connection: connection, lookupMethod: lookupMethod)
        case .activateConnection(let user, let redirectImmediately):
            transitionToActivate(connection: connection, user: user, redirectImmediately: redirectImmediately)
        case .activationComplete(let userToken):
            handleActivationFinished(userToken: userToken)
            transitionToActivationComplete(service: connection.connectingService)
        case .failed(let error):
            transitionToFailed(error: error)
        case .canceled:
            transitionToCanceled(connection: connection)
        case .connected(let animated):
            transitionToConnected(connection: connection, animated: animated)
        case .processDisconnect:
            transitionToProcessDisconnect()
        case .disconnected:
            handleDeactivationFinished()
            transitionToDisconnected(connection: connection)
        }
    }
    
    private func transitionToInitalization(connection: Connection, animated: Bool) {
        connectionVerificationSession.endActivationWebFlow()

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
        
        let transition: (() -> ConnectButton.Transition)? = { [weak self] in
            guard let self = self else {
                return initialButtonState
            }
            if self.connectionHandoffFlow.isAppHandoffAvailable || self.credentialProvider.userToken != nil {
                return .buttonState(.slideToConnect(service: nil, message: "button.state.verifying".localized))
            } else {
                return .buttonState(.enterEmail(service: connection.connectingService.connectButtonService, suggestedEmail: self.connectionConfiguration.suggestedUserEmail), footerValue: FooterMessages.enterEmail.value, duration: 0.5)
            }
        }
        
        let toggle: VoidClosure = { [weak self] in
            guard let self = self else { return }
            if let token = self.credentialProvider.userToken {
                self.transition(to: .identifyUser(.token(token)))
            } else if let handoffURL = self.connectionHandoffFlow.appHandoffUrl(userId: nil) {
                self.transition(to: .appHandoff(url: handoffURL, redirectImmediately: false))
            }
        }

        button.toggleInteraction.toggleDragTransition = transition
        button.toggleInteraction.toggleTapTransition = transition

        button.toggleInteraction.onToggleTap = toggle
        button.toggleInteraction.onToggleDrag = toggle

        button.emailInteraction.onConfirm = { [weak self] email in
            guard let self = self else {
                assertionFailure("It is expected that `self` is not nil here.")
                return
            }

            self.emailInteractionConfirmation(email: email)
        }
    }

    /// Redirects to the IFTTT app for the app handoff connection flow
    ///
    /// - Parameters:
    ///   - url: The handoff URL
    ///   - redirectImmediately: When true, do redirect immediately. Or delay to show progress bar.
    private func transitionToAppHandoff(url: URL, redirectImmediately: Bool) {
        let redirect = {
            let success = UIApplication.shared.openURL(url)
            if !success {
                self.transition(to: .failed(.iftttAppRedirectFailed))
            }
        }
        
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
        
        guard redirectImmediately == false else {
            redirect()
            return
        }
        
        let progress = button.showProgress(duration: 1)
        progress.addCompletion { _ in
            redirect()
        }
        progress.startAnimation()
    }
    
    private func transitionToIdentifyUser(connection: Connection, lookupMethod: User.LookupMethod) {
        connectionVerificationSession.beginObservingSafariRedirects(with: lookupMethod)
        button.animator(for: .buttonState(.verifying(message: "button.state.verifying".localized), footerValue: FooterMessages.worksWithIFTTT.value)).perform()

        button.footerInteraction.isTapEnabled = true

        // Pause at halfway here since we may follow up with the user account creation message
        let progress = ProgressBarController(progressBar: button, pauseAt: 0.5)
        progress.begin()
        
        let dataTask = connectionNetworkController.fetchUser(lookupMethod: lookupMethod) { [weak self] result in
            guard let self = self else {
                return
            }
            switch result {
            case .success(let user):
                self.user = user
                
                if user.isExistingUser {
                    // This is an existing IFTTT user but we don't have a token
                    // Send on to service authentication, web will take care of getting the user signed in
                    progress.finish {
                        if let handoffURL = self.connectionHandoffFlow.appHandoffUrl(userId: user.id) {
                            self.transition(to: .appHandoff(url: handoffURL, redirectImmediately: true))
                        } else {
                            self.transition(to: .activateConnection(user: user, redirectImmediately: true))
                        }
                    }
                } else {
                    // There is no account for this user
                    // Show a fake message that we are creating an account
                    // Then move to the first step of the service connection flow
                    progress.wait(until: 0.5) {
                        self.button.animator(for: .buttonState(
                            .createAccount(message: "button.state.creating_account".localized),
                            footerValue: FooterMessages.creatingAccount(email: user.id.value).value)
                            ).perform()
                        
                        progress.finish(extendingDurationBy: 1.5) {
                            self.transition(to: .activateConnection(user: user, redirectImmediately: false))
                        }
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

    private func transitionToActivate(connection: Connection, user: User, redirectImmediately: Bool) {
        Analytics.shared.track(.Click,
                               location: .connectButtonLocation(connection),
                               object: connection)
        
        let url = connectionHandoffFlow.webFlowUrl(user: user)
    
        if redirectImmediately {
            startWebConnectionVerification(with: url)
            return
        }
        
        let service = connection.connectingService
        
        button.footerInteraction.isTapEnabled = true
        button.animator(for: .buttonState(.continueToService(service: service.connectButtonService,
                                                             message: "button.state.sign_in".localized(with: service.name)),
                                          footerValue: FooterMessages.worksWithIFTTT.value)).perform()

        let timeout = 2.0
        button.showProgress(duration: timeout).startAnimation()
        
        Timer.scheduledTimer(withTimeInterval: timeout, repeats: false) { [weak self] timer in
            self?.startWebConnectionVerification(with: url)
            timer.invalidate()
        }
    }
    
    private func startWebConnectionVerification(with url: URL) {
        if #available(iOS 13.0, *) {
            guard let presentationContext = delegate?.webAuthenticationPresentationAnchor() else {
                assertionFailure("It is expected for the web flow in iOS versions >= 13.0 to implement the `webAuthenticationPresentationAnchor()` delegate method of `ConnectButtonControllerDelegate`.")
                return
            }
            
            connectionVerificationSession.start(with: url, in: presentationContext)
        } else {
            guard let viewController = delegate?.presentingViewController(for: self) else {
                assertionFailure("It is expected for the web flow in iOS versions < 12 to implement the `presentingViewController(for connectButtonController: ConnectButtonController)` delegate method of `ConnectButtonControllerDelegate`.")
                return
            }
           
            connectionVerificationSession.start(from: viewController, with: url)
        }
    }

    private func transitionToActivationComplete(service: Connection.Service) {
        Analytics.shared.track(.PageView,
                               location: .connectButtonLocation(connection))
        
        button.animator(for: .buttonState(.connecting(service: service.connectButtonService, message: "button.state.connecting".localized),
                                          footerValue: FooterMessages.worksWithIFTTT.value)).perform()

        let progress = button.showProgress(duration: 2)
        progress.perform()
        progress.addCompletion { _ in
            self.button.animator(for: .buttonState(.checkmark(service: service.connectButtonService))).perform()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                self.transition(to: .connected(animated: true))
            }
        }
    }

    private func transitionToFailed(error: ConnectButtonControllerError) {
        handleActivationFailed(error: error)
        transition(to: .initial(animated: false))
    }

    private func transitionToCanceled(connection: Connection) {
        handleActivationFailed(error: .canceled)
        transitionToInitalization(connection: connection, animated: true)
    }

    private func transitionToConnected(connection: Connection, animated: Bool) {
        button.animator(for: .buttonState(buttonState(forConnectionStatus: .enabled, service: connection.connectingService, shouldAnimateKnob: animated), footerValue: FooterMessages.worksWithIFTTT.value)).perform()
        
        button.footerInteraction.isTapEnabled = true
        button.footerInteraction.onSelect = { [weak self] in
            self?.showAboutPage()
        }
        
        // Toggle from here goes to disconnection confirmation
        // When the user taps the switch, they are asked to confirm disconnection by dragging the switch into the off position
        button.toggleInteraction.isTapEnabled = true
        button.toggleInteraction.isDragEnabled = true
        button.toggleInteraction.resistance = .heavy
        
        let toggleTransition: () -> ConnectButton.Transition = {
            return .buttonState(.disconnecting(message: "button.state.disconnecting".localized),
            footerValue: FooterMessages.worksWithIFTTT.value)
        }
        
        let onToggleProcess: VoidClosure = { [weak self] in
            self?.transition(to: .processDisconnect)
        }
        
        button.toggleInteraction.toggleTapTransition = toggleTransition
        button.toggleInteraction.toggleDragTransition = toggleTransition
        
        button.toggleInteraction.onToggleTap = onToggleProcess
        button.toggleInteraction.onToggleDrag = onToggleProcess
        
        button.toggleInteraction.onReverseDrag = { [weak self] in
            self?.transition(to: .connected(animated: false))
        }
    }

    private func transitionToProcessDisconnect() {
        guard let connection = connection else {
            assertionFailure("It is expected and required that we have a non nil connection in this state.")
            return
        }
        
        Analytics.shared.track(.Click,
                               location: .connectButtonLocation(connection),
                               object: connection)
        
        button.toggleInteraction = .init()

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

        Analytics.shared.track(.Click,
                               location: .connectButtonLocation(connection),
                               object: AnalyticsObject.email)
        
        if email.isValidEmail {
            self.transition(to: .identifyUser(.email(email)))
        } else {
            self.button.animator(for: .footerValue(FooterMessages.emailInvalid.value)).perform()
            self.button.performInvalidEmailAnimation()

            emailFooterTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { [weak self] timer in
                self?.button.animator(for: .footerValue(FooterMessages.enterEmail.value)).perform()
                timer.invalidate()
            }
        }
    }
}

extension ConnectButtonController: ConnectButtonAnalyticsDelegate {
    func trackSuggestedEmailImpression() {
        Analytics.shared.track(.Impression,
                               location: .connectButtonLocation(connection),
                               object: AnalyticsObject.email)
    }
}

// MARK: - Convenience

private extension Connection.Service {
    var connectButtonService: ConnectButton.Service {
        return ConnectButton.Service(iconURL: templateIconURL, brandColor: brandColor)
    }
}

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
