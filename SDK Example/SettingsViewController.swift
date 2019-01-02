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
    
    @IBAction func doneTapped(_ sender: Any) {
        settings.save()
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func emailChanged(_ sender: Any) {
        settings.email = emailField.text ?? ""
    }
    @IBAction func newUserChanged(_ sender: Any) {
        settings.forcesNewUserFlow = newUserSwitch.isOn
    }
    @IBAction func styleChanged(_ sender: Any) {
        settings.connectButtonStyle = connectButtonStyleControl.selectedSegmentIndex == Constants.lightStyleIndex ? .light : .dark
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        emailField.text = settings.email
        newUserSwitch.isOn = settings.forcesNewUserFlow
        switch settings.connectButtonStyle {
        case .light:
            connectButtonStyleControl.selectedSegmentIndex = Constants.lightStyleIndex
        case .dark:
            connectButtonStyleControl.selectedSegmentIndex = Constants.darkStyleIndex
        }
    }
}
