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
    
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var newUserSwitch: UISwitch!
    @IBOutlet weak var connectButtonStyleControl: UISegmentedControl!
    @IBOutlet weak var logoutView: UIStackView!
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
    @IBAction func logoutTapped(_ sender: Any) {
        ConnectionCredentials.reset()
        update()
    }
    
    private func update() {
        let credentials = ConnectionCredentials(settings: settings)
        if credentials.isLoggedIn {
            emailField.text = credentials.email
            emailField.isEnabled = false
            
            newUserSwitch.isOn = false
            newUserSwitch.isEnabled = false
            
            logoutView.isHidden = false
            credentialsTextView.text = credentials.description
        } else {
            emailField.text = settings.email
            emailField.isEnabled = true
            
            newUserSwitch.isOn = settings.forcesNewUserFlow
            newUserSwitch.isEnabled = true
            
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
