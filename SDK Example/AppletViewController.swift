//
//  ViewController.swift
//  SDK Example
//
//  Created by Jon Chmura on 8/31/18.
//  Copyright © 2018 IFTTT. All rights reserved.
//

import UIKit
import IFTTT_SDK

class AppletViewController: UIViewController {

    @IBOutlet weak var titleLabel: UILabel!
    
    @IBOutlet weak var descriptionLabel: UILabel!
    
    @IBOutlet weak var connectButton: ConnectButton!
    
    private var connectInteractor: ConnectInteractionController!
    
    var applet: Applet? {
        didSet {
            if let applet = applet, isViewLoaded {
                configure(with: applet)
            }
        }
    }
    
    private func configure(with applet: Applet) {
        titleLabel.text = applet.name
        descriptionLabel.text = applet.description
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let applet = applet {
            connectInteractor = ConnectInteractionController(connectButton, applet: applet)
            configure(with: applet)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        
    }
}

