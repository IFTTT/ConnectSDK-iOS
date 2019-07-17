//
//  SettingsViewController.swift
//  SDK Example
//
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
    @IBOutlet weak var fetchConnectionSwitch: UISwitch!
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
    @IBAction func fetchConnectionChanged(_ sender: Any) {
        settings.fetchConnectionFlow = fetchConnectionSwitch.isOn
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
            
            fetchConnectionSwitch.isOn = settings.fetchConnectionFlow
            fetchConnectionSwitch.isEnabled = true
            
            loginView.isHidden = true
            logoutView.isHidden = false
            credentialsTextView.text = credentials.description
        } else {
            emailField.text = settings.email
            emailField.isEnabled = true
            
            newUserSwitch.isOn = settings.forcesNewUserFlow
            newUserSwitch.isEnabled = true
            
            fetchConnectionSwitch.isOn = settings.fetchConnectionFlow
            fetchConnectionSwitch.isEnabled = true
            
            loginView.isHidden = false
            logoutView.isHidden = true
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        update()
    }
}
