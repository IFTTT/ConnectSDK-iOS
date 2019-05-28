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
    
    /// The various states the connect button can animate to.
    enum AnimationState {
        
        /// The loading state of the button when it is fetching a connection for the client.
        /// - message: The text you want to display during the step.
        case loading(message: String)
        
        /// The failure state if loading a connection for the client failed.
        case loadingFailed
        
        /// The initial state where the connection has loaded but the user hasn't started the activation process.
        /// - service: A model that includes info about the branding of the service to connect.
        /// - message: The text you want to display during the step.
        case connect(service: Service, message: String)
        
        /// The state when we show that we are creating a new account for the user.
        /// - message: The text you want to display during the step.
        case createAccount(message: String)
        
        /// The state to transition to when a user slides or taps to connect a service.
        /// - message: The text you want to display during the step.
        case slideToConnect(message: String)
        
        /// The state to transition to when a user slides or taps to connect a service. This is currently only being used by the IFTTT iOS app.
        /// - service: A model that includes info about the branding of the service to connect.
        /// - message: The text you want to display during this step.
        case slideToConnectService(service: Service, message: String)
        
        /// The state to transition to when a user slides to disconnect a service.
        /// - message: The text you want to display during the step.
        case slideToDisconnect(message: String)
        
        /// The state to show progress while we disconnect the connection.
        /// - message: The text you want to display during the step.
        case disconnecting(message: String)
        
        /// The state where we ask the user to enter their email.
        /// - service: A model that includes info about the branding of the service to connect.
        /// - suggestedEmail: A suggested email provided to auto populate the text field.
        case enterEmail(service: Service, suggestedEmail: String)
        
        /// The state to transition to when are verifying a users account.
        /// - message: The text you want to display during the step.
        case accessingAccount(message: String)
        
        /// The state to transition to when are verifying a users account.
        /// - message: The text you want to display during the step.
        case verifyingEmail(message: String)
        
        /// The state to transition to when we are about to continue to the service's website for authentication.
        /// - service: A model that includes info about the branding of the service to connect.
        /// - message: The text you want to display during this step.
        case continueToService(service: Service, message: String)
        
        /// The state to transition to when we are finishing up the activation process and are connecting the services.
        /// - service: A model that includes info about the branding of the service to connect.
        /// - message: The text you want to display during this step.
        case connecting(service: Service, message: String)
        
        /// The state to show a checkmark after the completion of the activation process.
        /// - service: A model that includes info about the branding of the service to connect.
        case checkmark(service: Service)
        
        /// The state to transition to when the connection has been activated.
        /// - service: A model that includes info about the branding of the service to connect.
        /// - message: The text you want to display during this step.
        /// - shouldAnimateKnob: Whether we should animate the knob turning on. We start out the knob in the center when animating to connected. If the knob is already in the correct location you can choose to not animated the knob from the center.
        case connected(service: Service, message: String, shouldAnimateKnob: Bool)
        
        /// The state to transition to when a connection is disconnected.
        /// - message: The text you want to display during the step.
        case disconnected(message: String)
    }
    
}
