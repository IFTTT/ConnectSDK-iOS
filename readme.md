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

### Setup 
#### Configure redirect
During Connection activation, your app will receive redirects intended for the Connect Button SDK. You must configure your app's PLIST file to accept incoming redirects with the same URL configured on https://platform.ifttt.com/services/<your_service>/embedded_redirects
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

#### Forward redirects to the Connect Button SDK
Use the `AuthenticationRedirectHandler` to process these redirects.

**Note:** the `authorizationRedirectURL` provide must be the same url provided in `ConnectionConfiguration` and used by `ConnectButtonController`.

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

#### CredentialProvider
* There are various codes and tokens you will need to provide the IFTTT SDK when authenticating your services to IFTTT
* Conform an object to `CredentialProvider` to handle these requirements.

* **partnerOAuthCode**: The OAuth code for your user on your service. This is used to skip a step for connecting to your own service during the Connect Button activation flow. We require this value to provide the best possible user experience. 
* **iftttServiceToken**: This is the token for your user on IFTTT for your service. This token allows you to get IFTTT user data related to only your service. For example, include this token to get the enabled status of Connections for your user. It is also the same token that is used to make trigger, query, and action requests for Connections on behave of the user. You should get this token from a communication between your servers and ours using your `IFTTT-Service-Key`. Never include this key in your app binary, rather create on endpoint on your own server to access the user's IFTTT service token.
* **inviteCode**: This value is only required if your service is not published. You can find it on https://platform.ifttt.com/services/<your_service>/general under invite URL.

```
struct Credentials: CredentialProvider {
    
    /// Provides the partner's OAuth code for a service during authentication with a `Connection`.
    var partnerOAuthCode: String { 
    	return theOAuthCodeForYourService
    }
    
    /// Provides the service's token associated with IFTTT.
    var iftttServiceToken: String? { 
    	return yourAppsKeychain["key_for_ifttt_token"]
    }
    
    /// Provides the invite code for testing an unpublished `Connection`'s services with the IFTTT platform.
    var inviteCode: String? { 
    	return "the invite code from platform.ifttt.com or nil if your service is published"
    }
}
```

### The Connect Button
#### Initialization
* Add a `ConnectButton` to your view controller
* `ConnectButton` supports `@IBDesignable` allowing you to add it directly in a Storyboard.
* Alternatively you can create it manually `let connectButton = ConnectButton()`

#### Fetching a Connection
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


#### Connect Button Controller Delegate
`ConnectButtonControllerDelegate` communicates important information back to you. Only one of its methods are required:
```
func presentingViewController(for connectButtonController: ConnectButtonController) -> UIViewController {
	return theViewControllerContainingTheConnectButton
}
```
We need access to the current view controller periodically to open instances of Safari for OAuth flows.

#### The IFTTT service user token
Once the user completes a Connection, it is important to update the IFTTT token used with your service. See `iftttServiceToken` above.
```
func connectButtonController(_ connectButtonController: ConnectButtonController, didFinishActivationWithResult result: Result<Connection, ConnectButtonControllerError>) {
	switch result {
	case .success(let connection):
	// The user succesfully enabled the Connection
	case .failure(let error):
	// There was a problem enabling the Connetion
	}
}
```
