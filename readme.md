## IFTTT SDK
IFTTT SDK is a iOS library in Swift that allows your users to activate programmable Connections directly in your app. 

<!-- TOC depthFrom:2 depthTo:6 withLinks:1 updateOnSave:1 orderedList:0 -->

- [Features](#features)
- [Requirements](#requirements)
- [Installation](#installation)
- [Setup](#setup)
- [The Connect Button](#the-connect-button)
- [Advanced](#advanced)


<!-- /TOC -->

## Features

- [x] Easily authenticate your services to IFTTT through the Connect Button
- [x] Configure the Connect Button through code or through interface builder with `IBDesignable`
- [x] Configure the ConnectButtonController to handle the Connection activation flow

## Requirements

* iOS 10.0+
* Xcode 10+
* Swift 4.0

## Installation

### Manually

#### Embedded Framework

- Download the project's folder, and drag the `IFTTT SDK.xcodeproj` into the Project Navigator of your application’s Xcode project.

    > It should appear nested underneath your application’s blue project icon. Whether it is above or below all the other Xcode groups does not matter.

- Select the `IFTTT SDK.xcodeproj` in the Project Navigator and verify the deployment target matches that of your application target.
- Next, select your application project in the Project Navigator (blue project icon) to navigate to the target configuration window and select the application target under the “Targets” heading in the sidebar.
- In the tab bar at the top of that window, open the “General” panel.
- Click on the `+` button under the “Embedded Binaries” section.    
- Select the top `IFTTT SDK.framework` for iOS.
- And that’s it!

The `IFTTT SDK.framework` is automatically added as a target dependency, linked framework and embedded framework in a “Copy Files” build phase which is all you need to build on the simulator and a device.

## Setup 
### Configure redirect
During Connection activation, your app will receive redirects intended for the Connect Button SDK. You must configure your app's PLIST file to accept incoming redirects with the same URL configured on the service tab in Redirects on https://platform.ifttt.com
```
<key>CFBundleURLTypes</key>
<array>
	<dict>
		<key>CFBundleTypeRole</key>
		<string>Viewer</string>
		<key>CFBundleURLName</key>
		<string>com.ifttt.sdk.example</string>
		<key>CFBundleURLSchemes</key>
		<array>
			<string>groceryexpress</string>
		</array>
	</dict>
</array>
```
### Supporting returning user flows
When the user making the connection is already a user on IFTTT, the activation flow may redirect outside of your app to verify the user's account. 
- If the IFTTT app is installed, the Connect Button SDK opens it to process a Connection activation flow. 
- If the IFTTT app is not installed, the user will receive a confirmation link in their email. In order to create a good user experience, we provide a link to user's email client. 
You must configure  `LSApplicationQueriesSchemes` in your app's PLIST file to support returning IFTTT users.
```
<key>LSApplicationQueriesSchemes</key>
<array>
    <string>ifttt-handoff-v1</string>
    <string>message</string>
    <string>googlegmail</string>
    <string>ms-outlook</string>
    <string>ymail</string>
    <string>airmail</string>
    <string>readdle-spark</string>
</array>
```

### Forward redirects to the Connect Button SDK
Use the `ConnectionRedirectHandler` to process these redirects.

**Note:** the `redirectURL` provide must be the same url provided in `ConnectionConfiguration` and used by `ConnectButtonController`.

```
func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
	if connectionRedirectHandler.handleApplicationRedirect(url: url, options: options) {
	    // This is an IFTTT SDK redirect, it will take over from here
	    return true
	} else {
	    // This is unrelated to the IFTTT SDK
	    return false
	}
}
``` 

### CredentialProvider
* There are various codes and tokens you will need to provide the IFTTT SDK when authenticating your services to IFTTT
* Conform an object to `CredentialProvider` to handle these requirements.

* `oauthCode`: The OAuth code for your user on your service. This is used to skip a step for connecting to your own service during the Connect Button activation flow. We require this value to provide the best possible user experience. 
* `userToken`: This is the IFTTT user token for your service. This token allows you to get IFTTT user data related to only your service. For example, include this token to get the enabled status of Connections for your user. It is also the same token that is used to make trigger, query, and action requests for Connections on behave of the user. You should get this token from a communication between your servers and ours using your `IFTTT-Service-Key`. Never include this key in your app binary, rather create on endpoint on your own server to access the user's IFTTT service token.
Additionally, the callback from ConnectButtonController returns the user token when a connection is made.
You should support both method, in the case that your user has already connected your service to IFTTT
* `inviteCode`: This value is only required if your service is not published. You can find it on https://platform.ifttt.com on the Service tab in General under invite URL. If your service is published, return nil.

```
struct Credentials: CredentialProvider {
    
    /// Provides the partner's OAuth code for a service during authentication with a `Connection`.
    var oauthCode: String { 
    	return theOAuthCodeForYourService
    }
    
    /// Provides the service's token associated with IFTTT.
    var userToken: String? { 
    	return yourAppsKeychain["key_for_ifttt_token"]
    }
    
    /// Provides the invite code for testing an unpublished `Connection`'s services with the IFTTT platform.
    var inviteCode: String? { 
    	return "the invite code from platform.ifttt.com or nil if your service is published"
    }
}
```

## The Connect Button

The Connect Button provides a consistent and simple way for your users to activate your programmable Connections.

### Initialization
* Add a `ConnectButton` to your view controller
* `ConnectButton` supports `@IBDesignable` allowing you to add it directly in a Storyboard.
* Alternatively you can create it manually `let connectButton = ConnectButton()`

### Layout and customization
The Connect Button is designed to fit into your UI just like any `UIKit` control. There are a few things you should know when creating the layout. 

1) The `ConnectButton` has 2 styles for placing it on a light or dark background
- Set this in code with `connectButton.style = .dark` 
- Or set this in Storyboard by setting `isLightStyle` in the inspector

![Light style](DocumentationAssets/button-light-style.jpeg) ![Dark style](DocumentationAssets/button-dark-style.jpeg)

2) The `ConnectButton` has a fixed height of 70 and a maximum width of 329
- The actual height of the `ConnectButton` with footer text will be slightly larger than this to accommodate the space for the text. You should allow the `ConnectButton` to calculate its height rather than setting any layout constraints on this as this will result in an invalid layout. 
- Horizontally, the `ConnectButton` is flexible. If you place it in a wider container than its maximum width, it centers itself in that container. 

3) The `ConnectButton` will prompt users to enter their email the first time that they activate a Connection. You must accommodate for the keyboard presentation in your UI.

‼️ Need to update the Connect Button graphic

### Configuring the `ConnectButtonController` 
Once you have the `ConnectButton` in your UI, you'll need to attach it to a `ConnectButtonController`. The controller handles the Connection activation flow. 

First you'll need to setup a `ConnectionConfiguration`
Second you'll need to configure a delegate 

#### ConnectionConfiguration
This configuration type provides information the `Connection` that you wish to use with the button and information about the user.
1) `connectionId`: The identifier for the `Connection`. You can find identifier for your programmatic Connections on platform.ifttt.com.
2) `suggestedUserEmail`: The email address that your user uses for your service. This allows us to prefill the email. 
3) `credentialProvider`: The `ConnectionCredentialProvider` you set up in [Setup](#setup)
4) `redirectURL`: The redirect URL you configured in [Setup](#setup)

#### ConnectButtonControllerDelegate
`ConnectButtonControllerDelegate` communicates important information back to your app.

We need access to the current view controller periodically to open instances of Safari for OAuth flows.
In this method, simply return the view controller containing the `ConnectButton`.
```
func presentingViewController(for connectButtonController: ConnectButtonController) -> UIViewController {
	return theViewControllerContainingTheConnectButton
}
```

When a `Connection` activation finishes, the controller calls this delegate method to inform your app. On successs, this method passes back the updated `Connection` and the IFTTT user token. It is important that you save the this token at this point. You'll need to pass it with `ConnectionCredentialProvider`, the next time the user visits a Connection page in your app. 

```
func connectButtonController(_ connectButtonController: ConnectButtonController,
                                 didFinishActivationWithResult result: Result<ConnectionActivation, ConnectButtonControllerError>) {
    switch result {
        case .success(let activation):
            // A Connection was activated and we received the user IFTTT token
            // Let's update our credential for this user
            if let token = activation.userToken {
                ourConnectionCredentials.loginUser(with: token)
            }
            
        case .failure(let error):
            break 
        }
}
```

Finally there is a callback when a Connection is disabled. You may want to adjust your UI. 

```
func connectButtonController(_ connectButtonController: ConnectButtonController,
                                 didFinishDeactivationWithResult result: Result<Connection, ConnectButtonControllerError>) {
     switch result {
        case .success(let updatedConnection):
            // The user disabled this Connection
            
        case .failure(let error):
            // Something went wrong while the user attempted to disable the Connection 
        }
}
```

#### Create the controller

Once you've setup the `ConnectionConfiguration` and the delegate, you can instanciate the controller. 

```
public init(connectButton: ConnectButton,
            connectionConfiguration: ConnectionConfiguration,
            delegate: ConnectButtonControllerDelegate)
```

That's it! You're ready to strart activating programmable Connections directly in your app. 


## Advanced

### Fetching a Connection
You may use `ConnectionNetworkController` directly to fetch a `Connection` from the Connection API. This is not a neccessary step. You could simply allow `ConnectButtonController` to do this. 

* Use `ConnectionNetworkController` to fetch your service’s `Connection`.
* `Connection.Request` handles creating the necessary `URLRequest`s.

```
connectionNetworkController.start(request: .fetchConnection(for: id, credentialProvider: yourCredentialProvider)) { response
	switch response.result {
	case .success(let connection):
		let config = ConnectionConfiguration(connection: connection,
                                     suggestedUserEmail: yourUsersEmail,
                                     credentialProvider: yourCredentialProvider,
                                     connectAuthorizationRedirectURL: theRedirectURLForYourIFTTTService)
				     
		self.connectButtonController = ConnectButtonController(connectButton: self.connectButton,
								       connectionConfiguration: config,
								       delegate: self)
	case .failure(let error):
		break
	}
}
```

Once you have a `Connection`, you can use an alternative initializer for `ConnectionConfiguration` that takes a `Connection`. Doing this will skip the loading state. 
