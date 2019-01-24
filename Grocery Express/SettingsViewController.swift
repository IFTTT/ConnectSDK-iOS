//
//  SettingsViewController.swift
//  SDK Example
//
//  Created by Jon Chmura on 1/2/19.
//  Copyright © 2019 IFTTT. All rights reserved.
//

import UIKit

class SettingsViewController: UIViewController {
    
    private struct Constants {
        static let lightStyleIndex = 0
        static let darkStyleIndex = 1
    }
    
    private var settings = Settings()
    
    private var connectionCredentials: ConnectionCredentials {
        // We may mutate `settings`
        // Rather than keeping the credentials state, let's generate it dynamically.
        return ConnectionCredentials(settings: settings)
    }
    
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var newUserSwitch: UISwitch!
    @IBOutlet weak var connectButtonStyleControl: UISegmentedControl!
    @IBOutlet weak var loginView: UIStackView!
    @IBOutlet weak var logoutView: UIStackView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var credentialsTextView: UITextView!
    
    @IBAction func doneTapped(_ sender: Any) {
        settings.save()
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func emailChanged(_ sender: Any) {
        settings.email = emailField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }
    @IBAction func newUserChanged(_ sender: Any) {
        settings.forcesNewUserFlow = newUserSwitch.isOn
    }
    @IBAction func styleChanged(_ sender: Any) {
        settings.connectButtonStyle = connectButtonStyleControl.selectedSegmentIndex == Constants.lightStyleIndex ? .light : .dark
    }
    @IBAction func loginTapped(_ sender: Any) {
        attemptLogin()
    }
    @IBAction func logoutTapped(_ sender: Any) {
        ConnectionCredentials(settings: settings).logout()
        update()
    }
    
    private func attemptLogin() {
        loginView.isHidden = true
        activityIndicator.startAnimating()
        
        let request = TokenRequest(credentials: connectionCredentials)
        request.start { [weak self] (_) in
            self?.activityIndicator.stopAnimating()
            self?.update()
        }
    }
    
    private func update() {
        let credentials = connectionCredentials
        if credentials.isLoggedIn {
            emailField.text = credentials.email
            emailField.isEnabled = false
            
            newUserSwitch.isOn = false
            newUserSwitch.isEnabled = false
            
            loginView.isHidden = true
            logoutView.isHidden = false
            credentialsTextView.text = credentials.description
        } else {
            emailField.text = settings.email
            emailField.isEnabled = true
            
            newUserSwitch.isOn = settings.forcesNewUserFlow
            newUserSwitch.isEnabled = true
            
            loginView.isHidden = false
            logoutView.isHidden = true
        }
        
        switch settings.connectButtonStyle {
        case .light:
            connectButtonStyleControl.selectedSegmentIndex = Constants.lightStyleIndex
        case .dark:
            connectButtonStyleControl.selectedSegmentIndex = Constants.darkStyleIndex
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        update()
    }
}
