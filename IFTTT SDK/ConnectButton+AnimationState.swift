//
//  ConnectButton+AnimationState.swift
//  IFTTT SDK
//
//  Created by Michael Amundsen on 5/23/19.
//  Copyright © 2019 IFTTT. All rights reserved.
//

import Foundation

@available(iOS 10.0, *)
extension ConnectButton {
    
    enum AnimationState {
        case loading(message: String)
        case loadingFailed
        case connect(service: Service, message: String)
        case createAccount(message: String)
        case slideToConnect(message: String)
        case slideToConnectService(service: Service, message: String)
        case slideToDisconnect(message: String)
        case disconnecting(message: String)
        case enterEmail(service: Service, suggestedEmail: String)
        case accessingAccount(message: String)
        case verifyingEmail(message: String)
        case continueToService(service: Service, message: String)
        case connecting(service: Service, message: String)
        case checkmark(service: Service)
        // We start out the knob in the center when animating to connected. If the knob is already in the correct location you can choose to not animated the knob from the center.
        case connected(service: Service, message: String, shouldAnimateKnob: Bool)
        case disconnected(message: String)
    }
    
}
