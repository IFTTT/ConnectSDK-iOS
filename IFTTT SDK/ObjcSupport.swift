//
//  ObjcSupport.swift
//  IFTTT SDK
//
//  Created by Jon Chmura on 8/30/18.
//  Copyright © 2018 IFTTT. All rights reserved.
//

import Foundation

@objc public protocol IFTTTUserTokenProviding: NSObjectProtocol {
    @objc func iftttUserToken() -> String?
}

@objc public class IFTTTAppletSession: NSObject {
    @objc public static let shared = IFTTTAppletSession()
    
    @objc public var userTokenProvider: IFTTTUserTokenProviding? {
        didSet {
            Applet.Session.shared.userTokenProvider = userTokenProvider != nil ? self : nil
        }
    }
}

extension IFTTTAppletSession: UserTokenProviding {
    public func iftttUserToken(for session: Applet.Session) -> String? {
        return userTokenProvider?.iftttUserToken()
    }
}

@objc public class IFTTTService: NSObject {
    @objc public let identifier: String
    @objc public let name: String
    @objc public let isPrimary: Bool
    @objc public let monochromeIconURL: URL
    @objc public let colorIconURL: URL
    @objc public let brandColor: UIColor
    @objc public let url: URL
    
    @nonobjc fileprivate init(service: Applet.Service) {
        identifier = service.id
        name = service.name
        isPrimary = service.isPrimary
        monochromeIconURL = service.monochromeIconURL
        colorIconURL = service.colorIconURL
        brandColor = service.brandColor
        url = service.url
    }
}

@objc public class IFTTTAppletResponse: NSObject {
    @objc public let urlResponse: URLResponse?
    @objc public let statusCode: NSNumber?
    @objc public let applet: IFTTTApplet?
    @objc public let error: Error?
    
    fileprivate init(response: Applet.Request.Response) {
        urlResponse = response.urlResponse
        statusCode = response.statusCode != nil ? NSNumber(integerLiteral: response.statusCode!) : nil
        switch response.result {
        case .success(let applet):
            self.applet = IFTTTApplet(applet: applet)
            self.error = nil
        case .failure(let error):
            self.applet = nil
            self.error = error
        }
    }
}

@objc public class IFTTTApplet: NSObject {
    
    @objc public let identifier: String
    @objc public let name: String
    @objc public let appletDescription: String
    @objc public let status: String
    @objc public let services: [IFTTTService]
    
    @nonobjc fileprivate init(applet: Applet) {
        identifier = applet.id
        name = applet.name
        appletDescription = applet.description
        status = applet.status.rawValue
        services = applet.services.map { IFTTTService(service: $0) }
    }
    
    @objc public static func getApplet(withId id: String, _ completion: @escaping (IFTTTAppletResponse) -> Void) {
        Applet.Request.applet(id: id) { (response) in
            completion(IFTTTAppletResponse(response: response))
        }
        .start()
    }
    
    @objc public static func updateApplet(withId id: String, isEnabled: Bool, _ completion: @escaping (IFTTTAppletResponse) -> Void) {
        Applet.Request.applet(id: id, setIsEnabled: isEnabled) { (response) in
            completion(IFTTTAppletResponse(response: response))
        }
        .start()
    }
}
