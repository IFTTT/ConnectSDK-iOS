//
//  AddressUpdateViewController.swift
//  Grocery Express
//
//  Copyright © 2021 IFTTT. All rights reserved.
//

import Foundation
import UIKit
import MapKit
import IFTTTConnectSDK

/// Generates a address update request based on the fields contained in the struct.
private struct AddressUpdateRequestFactory {
    let token: String
    let userId: String
    let entryPlacemark: MKPlacemark
    let entryAddress: String
    let entryRadius: Int
    let exitPlacemark: MKPlacemark
    let exitAddress: String
    let exitRadius: Int
    let connectionId: String
    
    func generate() -> URLRequest {
        let body = """
        {
          "user_id": \(userId),
          "services": [
            {
              "service_id": "location",
              "triggers": [
                {
                  "id": "exit_region_location",
                  "user_triggers": [
                    {
                      "fields": [
                        {
                          "id": "location",
                          "value": {
                            "address": "\(exitAddress)",
                            "lat": "\(exitPlacemark.coordinate.latitude)",
                            "lng": "\(exitPlacemark.coordinate.longitude)",
                            "radius": "\(exitRadius)"
                          }
                        }
                      ]
                    }
                  ]
                },
                {
                  "id": "enter_region_location",
                  "user_triggers": [
                    {
                      "fields": [
                        {
                          "id": "location",
                          "value": {
                            "address": "\(entryAddress)",
                            "lat": "\(entryPlacemark.coordinate.latitude)",
                            "lng": "\(entryPlacemark.coordinate.longitude)",
                            "radius": "\(entryRadius)"
                          }
                        }
                      ]
                    }
                  ]
                }
              ]
            }
          ]
        }
        """
        
        var request = URLRequest(url: URL(string: "https://connect.ifttt.com/v2/connections/\(connectionId)")!)
        request.httpMethod = "POST"
        request.httpBody = body.data(using: .utf8)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let tokenString = "Bearer \(token)"
        request.setValue(tokenString, forHTTPHeaderField: "Authorization")
        return request
    }
}

extension URLSession {
    static let addressUpdate: URLSession =  {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.httpAdditionalHeaders = ["Accept" : "application/json"]
        return URLSession(configuration: configuration)
    }()
}

/// A helper view to update the entry/exit geofences of a connection. This should only be used with connections that have entry and exit location triggers.
final class AddressUpdateViewController: UIViewController {
    @IBOutlet private weak var stackView: UIStackView!
    @IBOutlet private weak var enterAddressLabel: UILabel!
    @IBOutlet private weak var enterRadiusTextField: UITextField!
    @IBOutlet private weak var exitAddressLabel: UILabel!
    @IBOutlet private weak var exitRadiusTextField: UITextField!
    @IBOutlet private weak var updateButton: UIButton!
    @IBOutlet private weak var userIdTextField: UITextField!
    @IBOutlet private weak var activityIndicator: UIActivityIndicatorView!
    
    /// The user token that comes back from the `ConnectButtonControllerDelegate` method `didFinishActivationWithResult`
    private var token: String = ""
    
    /// The connection id to use in updating the address.
    private var connectionId: String = ""
    
    /// The `URLSession` that's used in updating the user's address.
    private let urlSession = URLSession.addressUpdate

    /// A class that assists in maintaining state of the update view
    class AddressUpdate {
        
        /// The geofence entry placemark
        var entryPlacemark: MKPlacemark?
        
        /// The geofence entry formatted address
        var entryAddress: String?
        
        /// The geofence radius for entry
        var geofenceEntryRadius: Int?
        
        /// The geofence exit placemark
        var exitPlacemark: MKPlacemark?
        
        /// The geofence radius for exit
        var geofenceExitRadius: Int?
        
        /// The geofence exit formatted address
        var exitAddress: String?
        
        /// The IFTTT user id for the user to update
        var userId: String?
    }

    private var addressUpdate: AddressUpdate = .init()
    
    static func instantiate(token: String, connectionId: String) -> AddressUpdateViewController {
        guard let viewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "AddressUpdateViewController") as? AddressUpdateViewController else {
            fatalError("Missing view controller with identifier AddressSelectionViewController in Main storyboard.")
        }
        viewController.token = token
        viewController.connectionId = connectionId
        return viewController
    }
    
    @IBAction private func enterAddressTapped(_ sender: Any) {
        let addressSelection = AddressSelectionViewController.instantiate()
        addressSelection.onAddressSelect = { [weak self] result in
            self?.addressUpdate.entryPlacemark = result.placemark
            self?.addressUpdate.entryAddress = result.formattedAddress
            self?.update()
            self?.dismiss(animated: true, completion: nil)
        }
        let navigationControllerWrapper = UINavigationController(rootViewController: addressSelection)
        present(navigationControllerWrapper, animated: true, completion: nil)
    }
    
    @IBAction private func exitAddressTapped(_ sender: Any) {
        let addressSelection = AddressSelectionViewController.instantiate()
        addressSelection.onAddressSelect = { [weak self] result in
            self?.addressUpdate.exitPlacemark = result.placemark
            self?.addressUpdate.exitAddress = result.formattedAddress
            self?.update()
            self?.dismiss(animated: true, completion: nil)
        }
        let navigationControllerWrapper = UINavigationController(rootViewController: addressSelection)
        present(navigationControllerWrapper, animated: true, completion: nil)
    }
    
    private func update() {
        configureLabels()
        configureUpdateButton()
    }
    
    private func configureLabels() {
        if let entry = addressUpdate.entryAddress {
            enterAddressLabel.text = entry
            enterAddressLabel.isHidden = false
        } else {
            enterAddressLabel.isHidden = true
        }
        
        if let exit = addressUpdate.exitAddress {
            exitAddressLabel.text = exit
            exitAddressLabel.isHidden = false
        } else {
            exitAddressLabel.isHidden = true
        }
    }
    
    private func configureUpdateButton() {
        updateButton.isEnabled = addressUpdate.entryPlacemark != nil
            && addressUpdate.exitPlacemark != nil
            && !(addressUpdate.userId?.isEmpty ?? true)
    }
    
    @IBAction private func updateButtonTapped(_ sender: Any) {
        activityIndicator.startAnimating()
        updateButton.isHidden = true
        makeRequest { [weak self] (data, error) in
            guard let self = self else { return }
            self.activityIndicator.stopAnimating()
            self.updateButton.isHidden = false
            if error != nil {
                let alert = UIAlertController(title: "Address update failed", message: "Please try again later.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Okay", style: .default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            } else if let data = data, data.isEmpty {
                ConnectButtonController.update()
                self.navigationController?.popViewController(animated: true)
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        userIdTextField.delegate = self
        enterRadiusTextField.delegate = self
        exitRadiusTextField.delegate = self
        
        if let enterRadiusText = enterRadiusTextField.text,
           let enterRadius = Int(enterRadiusText) {
            addressUpdate.geofenceEntryRadius = enterRadius
        }
        
        if let exitRadiusText = exitRadiusTextField.text,
           let exitRadius = Int(exitRadiusText) {
            addressUpdate.geofenceExitRadius = exitRadius
        }
        
        stackView.layoutMargins = .init(top: 20, left: 20, bottom: 0, right: 20)
        stackView.isLayoutMarginsRelativeArrangement = true
        update()
    }
    
    private func makeRequest(completion: @escaping (Data?, Error?) -> Void) {
        guard let userId = addressUpdate.userId,
              let entryPlacemark = addressUpdate.entryPlacemark,
              let entryAddress = addressUpdate.entryAddress?.replacingOccurrences(of: "\n", with: " "),
              let entryRadius = addressUpdate.geofenceEntryRadius,
              let exitPlacemark = addressUpdate.exitPlacemark,
              let exitAddress = addressUpdate.exitAddress?.replacingOccurrences(of: "\n", with: " "),
              let exitRadius = addressUpdate.geofenceExitRadius else { return }
        let requestFactory = AddressUpdateRequestFactory(token: token,
                                                         userId: userId,
                                                         entryPlacemark: entryPlacemark,
                                                         entryAddress: entryAddress,
                                                         entryRadius: entryRadius,
                                                         exitPlacemark: exitPlacemark,
                                                         exitAddress: exitAddress,
                                                         exitRadius: exitRadius,
                                                         connectionId: connectionId)
        let task = urlSession.dataTask(with: requestFactory.generate()) { (data, response, error) in
            DispatchQueue.main.async {
                completion(data, error)
            }
        }
        task.resume()
    }
}

extension AddressUpdateViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        defer {
            configureUpdateButton()
        }
        
        guard let text = textField.text else { return true }
        let updatedText = (text as NSString).replacingCharacters(in: range, with: string)
        
        if textField == userIdTextField {
            addressUpdate.userId = updatedText
        } else if textField == enterRadiusTextField {
            addressUpdate.geofenceEntryRadius = Int(updatedText)
        } else if textField == exitRadiusTextField {
            addressUpdate.geofenceExitRadius = Int(updatedText)
        }
        
        return true
    }
}
