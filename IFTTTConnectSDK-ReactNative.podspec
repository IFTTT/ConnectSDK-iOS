Pod::Spec.new do |spec|
  spec.name             = "IFTTTConnectSDK-ReactNative"
  spec.version          = "2.8.0"
  spec.summary          = "Allows your users to activate programmable IFTTT Connections directly in your React Native iOS app."
  spec.description      = <<-DESC
  - Easily authenticate your services to IFTTT through the Connect Button
  - Configure the Connect Button through code
  - Configure the ConnectButtonController to handle the Connection activation flow
  DESC
  spec.homepage         = "https://github.com/IFTTT/ConnectSDK-iOS"
  spec.license          = { :type => "MIT", :file => "LICENSE" }
  spec.author           = { "Siddharth Sathyam" => "siddharth@ifttt.com" }
  spec.platform         = :ios, "10.0"
  spec.swift_version    = "5.0"
  spec.source           = { :git => "https://github.com/IFTTT/ConnectSDK-iOS.git",  :branch => "feature/adding_react_native_support" }
  spec.source_files     = "IFTTT SDK/**/*.swift"
  spec.resource_bundles = {
    'IFTTTConnectSDK' => ['IFTTT SDK/Resources/Assets.xcassets'],
    'IFTTTConnectSDK-Localizations' => ['IFTTT SDK/Resources/*.strings']
  }
end
