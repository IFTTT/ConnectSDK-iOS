//
//  ConnectionViewController.swift
//  SDK Example
//
//  Created by Jon Chmura on 1/2/19.
//  Copyright © 2019 IFTTT. All rights reserved.
//

import UIKit
import IFTTT_SDK

class ConnectionViewController: UIViewController {
    
    struct Constants {
        static let connectionId = "fWj4fxYg"
    }
    
    // MARK: - UI
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    @IBOutlet weak var connectButton: ConnectButton!
    
    @IBOutlet weak var valuePropsView: UIImageView!
    
    
    // MARK: - Connect flow
    
    private let settings = Settings()
    
    private lazy var connectionCredentials = ConnectionCredentials(settings: settings)
    
    private var connectButtonController: ConnectButtonController?
    
    private func setupConnectButtonController(_ configuration: ConnectionConfiguration) {
        activityIndicator.stopAnimating()
        connectButton.isHidden = false
        valuePropsView.isHidden = false
        
        connectButtonController = ConnectButtonController(connectButton: connectButton,
                                                          connectionConfiguration: configuration,
                                                          delegate: self)
    }
    
    
    // MARK: - Fetch the connection
    
    private let connectionNetworkController = ConnectionNetworkController()
 
    private func fetchConnection(with id: String) {
        if settings.fetchConnectionFlow {
            let connectionConfiguration = ConnectionConfiguration(connectionId: id,
                                                                  suggestedUserEmail: self.connectionCredentials.email,
                                                                  credentialProvider: self.connectionCredentials,
                                                                  redirectURL: AppDelegate.connectionRedirectURL)
            self.setupConnectButtonController(connectionConfiguration)
        } else {
            activityIndicator.startAnimating()
            connectButton.isHidden = true
            valuePropsView.isHidden = true
            
            connectionNetworkController.start(request: .fetchConnection(for: id, credentialProvider: connectionCredentials)) { [weak self] response in
                guard let self = self else { return }
                
                switch response.result {
                case .success(let connection):
                    let connectionConfiguration = ConnectionConfiguration(connection: connection,
                                                                          suggestedUserEmail: self.connectionCredentials.email,
                                                                          credentialProvider: self.connectionCredentials,
                                                                          redirectURL: AppDelegate.connectionRedirectURL)
                    self.setupConnectButtonController(connectionConfiguration)
                    
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
    
    
    // MARK: - UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let style = Settings().connectButtonStyle
        let backgroundColor: UIColor = style == .light ? .white : .black
        let foregroundColor: UIColor = style == .light ? .black : .white
        
        connectButton.style = style
        view.backgroundColor = backgroundColor
        valuePropsView.tintColor = foregroundColor
        activityIndicator.color = foregroundColor
        
        fetchConnection(with: Constants.connectionId)
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
