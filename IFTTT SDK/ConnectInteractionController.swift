//
//  ConnectInteractionController.swift
//  IFTTT SDK
//
//  Created by Jon Chmura on 9/19/18.
//  Copyright © 2018 IFTTT. All rights reserved.
//

import UIKit

public class ConnectInteractionController {
    
    let button: ConnectButton
    
    let applet: Applet
    
    public init(_ button: ConnectButton, applet: Applet) {
        self.button = button
        self.applet = applet
        
        button.transition(to: .connect(applet.services.first!))
    }
}
