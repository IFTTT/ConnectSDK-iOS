Pod::Spec.new do |spec|
  spec.name             = "IFTTTConnectSDK"
  spec.version          = "2.5.0"
  spec.summary          = "Allows your users to activate programmable IFTTT Connections directly in your app."
  spec.description      = <<-DESC
  - Easily authenticate your services to IFTTT through the Connect Button
  - Configure the Connect Button through code or through interface builder with IBDesignable
  - Configure the ConnectButtonController to handle the Connection activation flow
  DESC
  spec.homepage         = "https://github.com/IFTTT/ConnectSDK-iOS"
  spec.license          = { :type => "MIT", :file => "LICENSE" }
  spec.author           = { "Siddharth Sathyam" => "siddharth@ifttt.com" }
  spec.platform         = :ios, "10.0"
  spec.swift_version    = "5.0"
  spec.source           = { :git => "https://github.com/IFTTT/ConnectSDK-iOS.git",  :tag => "#{spec.version}" }
  spec.source_files     = "IFTTT SDK/**/*.swift"
  spec.resource_bundles = {
    'IFTTTConnectSDK' => ['IFTTT SDK/Assets.xcassets'],
    'IFTTTConnectSDK-Localizations' => ['IFTTT SDK/*.strings']
  }
end
