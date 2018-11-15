<img width="363" alt="screen shot 2018-11-15 at 4 14 36 pm" src="https://user-images.githubusercontent.com/16432044/48582131-a652b280-e8f1-11e8-8ea0-f05861f7823d.png">

## IFTTT SDK
IFTTT SDK is a iOS library in Swift that lets your users authenticate your services to IFTTT. 

<!-- TOC depthFrom:2 depthTo:6 withLinks:1 updateOnSave:1 orderedList:0 -->

- [Features](#features)
- [Requirements](#requirements)
- [Installation](#installation)
- [Usage](#usage)

<!-- /TOC -->

## Features

- [x] Easily authenticate your services to IFTTT through the Connect Button
- [x] Configure the Connect Button through code or through interface builder with `IBDesignable`
- [x] Configure the ConnectButtonController and it will handle the rest of the authentication process.

## Requirements

* iOS 10.0+
* Xcode 10+
* Swift 4.2

## Installation

### Manually

#### Embedded Framework

- Download the projects  `IFTTT-SDK-iOS-Sandbox-` folder, and drag the `IFTTT SDK.xcodeproj` into the Project Navigator of your application’s Xcode project.

    > It should appear nested underneath your application’s blue project icon. Whether it is above or below all the other Xcode groups does not matter.

- Select the `IFTTT SDK.xcodeproj` in the Project Navigator and verify the deployment target matches that of your application target.
- Next, select your application project in the Project Navigator (blue project icon) to navigate to the target configuration window and select the application target under the “Targets” heading in the sidebar.
- In the tab bar at the top of that window, open the “General” panel.
- Click on the `+` button under the “Embedded Binaries” section.    
- Select the top `IFTTT SDK.framework` for iOS.
- And that’s it!

The `IFTTT SDK.framework` is automatically added as a target dependency, linked framework and embedded framework in a “Copy Files” build phase which is all you need to build on the simulator and a device.

## Usage

Once IFTTT SDK  is installed, it’s simple to use.

You will use the `ConnectButtonController` to interact and handle authenticating your service to IFTTT.

### Setup CredentialProvider
* There are various codes and tokens you will need to provide the IFTTT SDK when authenticating your services to IFTTT
* Conform an object to `CredentialProvider` to handle these requirements.

### Fetch A Connection
* You will want to use `ConnectionNetworkController` to fetch your service’s `Connection`.
* `Connection.Request` handles creating the necessary `URLRequest`s.

### Using the Connect Button
* You will need to provide the `ConnectButtonController` a `ConnectButton`.
* The `ConnectButton` should be presented in one of the views on your view controller. 
	* You will also want this view controller to conform to `ConnectButtonControllerDelegate`.
* Also provide the `ConnectButtonController ` a `ConnectionConfiguration` which includes key information for the authentication process.

### Handling Redirects
* During the authentication process, your app will receive redirect urls to open.
* Use the `AuthenticationRedirectHandler` to process these redirects.
	* **Note:** the `authorizationRedirectURL` provide must be the same url provided to the `ConnectionConfiguration` used by `ConnectButtonController`.

From here, the user can interact with the `ConnectButton` and the SDK will communicate important information back to you through the `ConnectButtonControllerDelegate`.
