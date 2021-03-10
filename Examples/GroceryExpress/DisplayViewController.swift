//
//  DisplayViewController.swift
//  Grocery Express
//
//  Copyright © 2020 IFTTT. All rights reserved.
//

import Foundation
import UIKit

struct DisplayInformation {
    let connectionId: String
    let hideOpaqueOverlay: Bool
    let headerImage: UIImage
    let subtitleText: String
    let showLocationUpdateWithSkipConfig: Bool
    
    static let calendarConnection = DisplayInformation(connectionId: "fWj4fxYg",
                                                       hideOpaqueOverlay: true,
                                                       headerImage: #imageLiteral(resourceName: "calendar_connection_image"),
                                                       subtitleText: "Delivered when you're at home",
                                                       showLocationUpdateWithSkipConfig: false)
    
    static let locationConnection = DisplayInformation(connectionId: "pWisyzm7",
                                                       hideOpaqueOverlay: false,
                                                       headerImage: #imageLiteral(resourceName: "location_connection_image"),
                                                       subtitleText: "Delivered when you're at a location",
                                                       showLocationUpdateWithSkipConfig: true)
}

class DisplayViewController: UIViewController {
    @IBOutlet weak var calendarConnectionView: UIView!
    @IBOutlet weak var locationConnectionView: UIView!
    
    private let calendarConnectionGestureRecognizer = UITapGestureRecognizer()
    private let locationConnectionGestureRecognizer = UITapGestureRecognizer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        calendarConnectionView.addGestureRecognizer(calendarConnectionGestureRecognizer)
        locationConnectionView.addGestureRecognizer(locationConnectionGestureRecognizer)
        
        calendarConnectionGestureRecognizer.addTarget(self, action: #selector(calendarConnectionViewTapped))
        locationConnectionGestureRecognizer.addTarget(self, action: #selector(locationConnectionViewTapped))
    }
    
    @objc func calendarConnectionViewTapped(gestureRecognizer: UIGestureRecognizer) {
        navigationController?.pushViewController(ConnectionViewController.instantiate(with: .calendarConnection), animated: true)
    }
    
    @objc func locationConnectionViewTapped(gestureRecognizer: UIGestureRecognizer) {
        navigationController?.pushViewController(ConnectionViewController.instantiate(with: .locationConnection), animated: true)
    }
}
