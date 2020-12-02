//
//  ConnectionViewController.swift
//  SDK Example
//
//  Copyright © 2019 IFTTT. All rights reserved.
//

import UIKit
import IFTTTConnectSDK
import AuthenticationServices

class ConnectionViewController: UIViewController {
    
    private var displayInformation: DisplayInformation!

    static func instantiate(with information: DisplayInformation) -> ConnectionViewController {
        guard let viewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ConnectionViewController") as? ConnectionViewController else {
            fatalError("Missing view controller with identifier ConnectionViewController in Main storyboard.")
        }
        viewController.displayInformation = information
        return viewController
    }
    
    // MARK: - UI
    
    @IBOutlet weak var backgroundImage: UIImageView!
    
    @IBOutlet weak var subtitle: UILabel!
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    @IBOutlet weak var connectButton: ConnectButton!
    
    @IBOutlet weak var featuresStackView: UIStackView!
    
    @IBOutlet weak var opaqueOverlay: UIView!
    
    // MARK: - Connect flow
    
    private let settings = Settings()
    
    private lazy var connectionCredentials = ConnectionCredentials(settings: settings)
    
    private var connectButtonController: ConnectButtonController?
    
    private func setupConnectButtonController(_ configuration: ConnectionConfiguration) {
        activityIndicator.stopAnimating()
        connectButton.isHidden = false
        featuresStackView.isHidden = false
        
        connectButtonController = ConnectButtonController(connectButton: connectButton,
                                                          connectionConfiguration: configuration,
                                                          locale: settings.locale,
                                                          delegate: self)
    }
    
    
    // MARK: - Fetch the connection
    
    private let connectionNetworkController = ConnectionNetworkController()
 
    private func fetchConnection(with id: String) {
        if settings.fetchConnectionFlow {
            let connectionConfiguration = ConnectionConfiguration(connectionId: id,
                                                                  suggestedUserEmail: self.connectionCredentials.email,
                                                                  credentialProvider: self.connectionCredentials,
                                                                  redirectURL: AppDelegate.connectionRedirectURL,
                                                                  skipConnectionConfiguration: settings.skipConnectionConfiguration)
            self.setupConnectButtonController(connectionConfiguration)
        } else {
            activityIndicator.startAnimating()
            connectButton.isHidden = true
            featuresStackView.isHidden = true
            
            connectionNetworkController.start(request: .fetchConnection(for: id, credentialProvider: connectionCredentials)) { [weak self] response in
                guard let self = self else { return }
                
                switch response.result {
                case .success(let connection):
                    let connectionConfiguration = ConnectionConfiguration(connection: connection,
                                                                          suggestedUserEmail: self.connectionCredentials.email,
                                                                          credentialProvider: self.connectionCredentials,
                                                                          redirectURL: AppDelegate.connectionRedirectURL,
                                                                          skipConnectionConfiguration: self.settings.skipConnectionConfiguration)
                    self.setupConnectButtonController(connectionConfiguration)
                    self.setupFeatures(with: connection)
                case .failure:
                    let alertController = UIAlertController(title: "Oops", message: "We were not able to retrieve the selected Connection. Please check your network connection.", preferredStyle: .alert)
                    let okAction = UIAlertAction(title: "Okay", style: .default, handler: { _ in
                        self.navigationController?.popViewController(animated: true)
                    })
                    alertController.addAction(okAction)
                    self.present(alertController, animated: true, completion: nil)
                }
            }
        }
    }
    
    // Displays the features on the UI.
    private func setupFeatures(with connection: Connection) {
        if !featuresStackView.arrangedSubviews.isEmpty {
            featuresStackView.removeAllArrangedSubviews()
        }
        
        connection.features.map { model -> FeatureDescriptionView in
            let featureDescriptionView = FeatureDescriptionView()
            featureDescriptionView.update(with: model)
            return featureDescriptionView
        }
        .forEach { featuresStackView.addArrangedSubview($0) }
    }
    
    // MARK: - UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        featuresStackView.isLayoutMarginsRelativeArrangement = true
        featuresStackView.layoutMargins = .init(top: 0, left: 20, bottom: 0, right: 20)
        view.backgroundColor = .white
        activityIndicator.color = .black
        
        update(with: displayInformation)
    }
    
    private func update(with display: DisplayInformation) {
        backgroundImage.image = displayInformation.headerImage
        subtitle.text = displayInformation.subtitleText
        opaqueOverlay.isHidden = displayInformation.hideOpaqueOverlay
        fetchConnection(with: displayInformation.connectionId)
    }

    /// A view that displays features on the UI.
    private class FeatureDescriptionView: UIView {

        var iconImageView = UIImageView()
        
        private struct Constants {
            static let ImageViewSize: CGFloat = 25
            static let Spacing: CGFloat = 20
            static let TextColor: UIColor = .black
            static let TextFont = UIFont(name: "Avenir-Medium", size: 16)!
        }
        
        private lazy var valueLabel: UILabel = {
            let label = UILabel()
            label.textColor = Constants.TextColor
            label.font = Constants.TextFont
            label.numberOfLines = 0
            return label
        }()
        
        private lazy var stackView: UIStackView = {
            let stackView = UIStackView(arrangedSubviews: [iconImageView, valueLabel])
            stackView.axis = .horizontal
            stackView.alignment = .center
            stackView.distribution = .fillProportionally
            stackView.spacing = Constants.Spacing
            return stackView
        }()
        
        init() {
            super.init(frame: .zero)
            iconImageView.contentMode = .scaleAspectFit
            iconImageView.addConstraints(iconImageView.sizeConstraints(size: .init(width: Constants.ImageViewSize, height: Constants.ImageViewSize)))
            
            addSubview(stackView)
            stackView.translatesAutoresizingMaskIntoConstraints = false
            addConstraints(fillConstraints(view: stackView))
            
            // This is done to ensure that the value label takes up the full possible width possible but at the same time, the enable switch hugs the content around it as tight as possible.
            valueLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        func update(with feature: Connection.Feature) {
            iconImageView.setURL(feature.iconURL)
            valueLabel.text = feature.title
        }
    }
}


// MARK: - Connect Button Delegate

private extension ConnectButtonControllerError {
    var reason: String? {
        switch self {
        case .iftttAccountCreationFailed:
            return "Failed to create IFTTT account"
        case .networkError(let error):
            return error.localizedDescription 
        case .unknownRedirect, .unknownResponse:
            return "Unknown error"
        case .userCancelledConfiguration:
            return "User cancelled configuration of the connection"
        case .canceled:
            return nil
        case .unableToGetConnection:
            return "The connection being used is nil"
        case .iftttAppRedirectFailed:
            return "Could not open the IFTTT app for handoff flow"
        }
    }
}

extension ConnectionViewController: ConnectButtonControllerDelegate {
    @available(iOS 13.0, *)
    func webAuthenticationPresentationAnchor() -> ASPresentationAnchor {
        return view.window ?? ASPresentationAnchor()
    }
    
    func presentingViewController(for connectButtonController: ConnectButtonController) -> UIViewController {
        return self
    }
    
    func connectButtonController(_ connectButtonController: ConnectButtonController,
                                 didFinishActivationWithResult result: Result<ConnectionActivation, ConnectButtonControllerError>) {
        switch result {
        case .success(let activation):
            // A Connection was activated and we received the user's service-level IFTTT token
            // Let's update our credential for this user
            if let token = activation.userToken {
                connectionCredentials.loginUser(with: token)
            }
            
        case .failure(let error):
            if let reason = error.reason {
                let alert = UIAlertController(title: "Connection failed", message: reason, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Okay", style: .default, handler: nil))
                present(alert, animated: true, completion: nil)
            }
        }
    }
    
    func connectButtonController(_ connectButtonController: ConnectButtonController,
                                 didFinishDeactivationWithResult result: Result<Connection, ConnectButtonControllerError>) {
        // Received when the Connection is deactivated.
    }
}
