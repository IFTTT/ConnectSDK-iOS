//
//  LoginViewController.swift
//  SDK Example
//
//  Created by Jon Chmura on 10/25/18.
//  Copyright © 2018 IFTTT. All rights reserved.
//

import UIKit

class LoginViewController: UIViewController {
    
    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 20, weight: .bold)
        label.numberOfLines = 0
        label.text = "IFTTT API Example - username field will accept any value"
        label.textAlignment = .center
        return label
    }()
    
    lazy var usernameField: UITextField = {
        let field = UITextField(frame: .zero)
        field.placeholder = "Enter username"
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        return field
    }()
    
    lazy var confirmButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Login", for: [])
        button.addTarget(self, action: #selector(confirmTapped), for: .touchUpInside)
        return button
    }()
    
    @objc func confirmTapped() {
        loginExampleAppUser()
    }
    
    lazy var stackView: UIStackView = {
        let view = UIStackView(arrangedSubviews: [titleLabel, usernameField, confirmButton])
        view.axis = .vertical
        view.spacing = 20
        view.isLayoutMarginsRelativeArrangement = true
        view.layoutMargins = UIEdgeInsets(top: 120, left: 20, bottom: 20, right: 20)
        return view
    }()
    
    func extractToken(from data: Data?) -> String? {
        guard
            let data = data,
            let jsonObject = try? JSONSerialization.jsonObject(with: data),
            let json = jsonObject as? [String : String],
            let token = json["token"]
        else {
            return nil
        }
        return token
    }
    
    func loginFailed(_ statusCode: Int) {
        let alert = UIAlertController(title: "Login failed: \(statusCode)", message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Okay", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    func loginExampleAppUser() {
        guard let user = usernameField.text else { return }
        
        let url = URL(string: "https://ifttt-api-example.herokuapp.com/mobile_api/log_in?username=\(user)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        URLSession.shared.dataTask(with: request) { (data, response, _) in
            DispatchQueue.main.async {
                let statusCode = (response as? HTTPURLResponse)?.statusCode
                if let token = self.extractToken(from: data) {
                    IFTTTAuthenication.shared.apiExampleOauthToken(token)
                    self.loginIftttUser(token)
                } else {
                    self.loginFailed(statusCode!)
                }
            }
        }.resume()
    }
    
    func loginIftttUser(_ token: String) {
        let url = URL(string: "https://ifttt-api-example.herokuapp.com/mobile_api/get_ifttt_token")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.httpMethod = "POST"
        URLSession.shared.dataTask(with: request) { (data, response, _) in
            DispatchQueue.main.async {
                IFTTTAuthenication.shared.setIftttUserToken(self.extractToken(from: data))
                AppDelegate.shared?.login()
            }
        }.resume()   
    }
    
    override func loadView() {
        super.loadView()
        
        usernameField.delegate = self
        
        view.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        stackView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        stackView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
    }
}

extension LoginViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        loginExampleAppUser()
        return true
    }
}
