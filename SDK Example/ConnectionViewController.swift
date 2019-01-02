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
        static let connectionId = "dngPHVFe"
    }
    
    // MARK: - UI
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    @IBOutlet weak var connectButton: ConnectButton!
    
    @IBOutlet weak var valuePropsView: UIImageView!
    
    
    // MARK: - Connect flow
    
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
        activityIndicator.startAnimating()
        connectButton.isHidden = true
        valuePropsView.isHidden = true
        
        connectionNetworkController.start(request: .fetchConnection(for: id, credentialProvider: IFTTTAuthenication.shared)) { [weak self] response in
            switch response.result {
            case .success(let connection):
                let connectionConfiguration = ConnectionConfiguration(connection: connection,
                                                                      suggestedUserEmail: Settings().connectFlowEmail,
                                                                      credentialProvider: IFTTTAuthenication.shared,
                                                                      connectAuthorizationRedirectURL: AppDelegate.connectionRedirectURL)
                self?.setupConnectButtonController(connectionConfiguration)
                
            case .failure:
                let alertController = UIAlertController(title: "Oops", message: "We were not able to retrieve the selected Connection. Please check your network connect.", preferredStyle: .alert)
                let okAction = UIAlertAction(title: "OK", style: .default, handler: { _ in
                    self?.navigationController?.popViewController(animated: true)
                })
                alertController.addAction(okAction)
                self?.present(alertController, animated: true, completion: nil)
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

extension ConnectionViewController: ConnectButtonControllerDelegate {
    func presentingViewController(for connectButtonController: ConnectButtonController) -> UIViewController {
        return self
    }
    
    func connectButtonController(_ connectButtonController: ConnectButtonController, didFinishActivationWithResult result: Result<Connection>) {
        switch result {
        case .success:
            break
        case .failure(let error):
            if let connectionError = error as? ConnectButtonControllerError {
                switch connectionError {
                case .iftttAccountCreationFailed:
                    break
                    
                case .networkError(let networkError):
                    break
                    
                case .unknownRedirect, .unknownResponse:
                    break
                    
                case .canceled:
                    break
                }
            }
        }
    }
    
    func connectButtonController(_ connectButtonController: ConnectButtonController, didFinishDeactivationWithResult result: Result<Connection>) {
        
    }
    
    func connectButtonController(_ connectButtonController: ConnectButtonController, didRecieveInvalidEmail email: String) {
        
    }
}
