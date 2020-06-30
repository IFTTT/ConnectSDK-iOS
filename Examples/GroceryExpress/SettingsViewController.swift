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
    @IBOutlet weak var skipConfigSwitch: UISwitch!
    @IBOutlet weak var newUserSwitch: UISwitch!
    @IBOutlet weak var fetchConnectionSwitch: UISwitch!
    @IBOutlet weak var loginView: UIStackView!
    @IBOutlet weak var logoutView: UIStackView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var credentialsTextView: UITextView!
    @IBOutlet weak var localeOverrideTextField: UITextField!
    private let localePickerView = UIPickerView()
    
    @IBAction func doneTapped(_ sender: Any) {
        settings.save()
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func emailChanged(_ sender: Any) {
        settings.email = emailField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }
    @IBAction func skipConfigChanged(_ sender: Any) {
        settings.skipConnectionConfiguration = skipConfigSwitch.isOn
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
        
        skipConfigSwitch.isOn = settings.skipConnectionConfiguration
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
        
        localePickerView.delegate = self
        localePickerView.dataSource = self
        
        localeOverrideTextField.delegate = self
        localeOverrideTextField.inputView = localePickerView
        localeOverrideTextField.text = settings.locale.identifier
        localeOverrideTextField.spellCheckingType = .no
        
        update()
    }
}

extension SettingsViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if let text = textField.text {
            let updatedText = (text as NSString).replacingCharacters(in: range, with: string)
            settings.locale = Locale(identifier: updatedText)
        }
        return true
    }
}

extension SettingsViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return Locale.availableIdentifiers.count
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let selectedIdentifier = Locale.availableIdentifiers[row]
        localeOverrideTextField.text = selectedIdentifier
        settings.locale = Locale(identifier: selectedIdentifier)
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return Locale.availableIdentifiers[row]
    }
}
