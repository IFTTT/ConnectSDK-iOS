//
//  ObjcSupport.swift
//  IFTTT SDK
//
//  Created by Jon Chmura on 8/30/18.
//  Copyright © 2018 IFTTT. All rights reserved.
//

import Foundation

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
    @objc public let applets: [IFTTTApplet]
    @objc public let error: Error?
    
    fileprivate init(response: Applet.Request.Response) {
        urlResponse = response.urlResponse
        statusCode = response.statusCode != nil ? NSNumber(integerLiteral: response.statusCode!) : nil
        switch response.result {
        case .success(let applets):
            self.applets = applets.map { IFTTTApplet(applet: $0) }
            self.error = nil
        case .failure(let error):
            self.applets = []
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
    
    @objc public static func getApplets(forService serviceId: String,
                                 limit: NSNumber?, nextPage: String?, sort: String?, filter: String?,
                                 _ completion: @escaping (IFTTTAppletResponse) -> Void) {
        var parameters = [Applet.Request.Parameter]()
        if let limit = limit {
            parameters.append(.limit(limit.intValue))
        }
        if let nextPage = nextPage {
            parameters.append(.nextPage(nextPage))
        }
        if let sort = Applet.Request.Parameter.Sort(rawValue: sort ?? "") {
            parameters.append(.sort(sort))
        }
        if let filter = Applet.Request.Parameter.Filter(rawValue: filter ?? "") {
            parameters.append(.filter(filter))
        }
        Applet.Request.applets(forService: serviceId, parameters: parameters) { (response) in
            completion(IFTTTAppletResponse(response: response))
        }
        .start()
    }
    
    @objc public static func getApplet(forService serviceId: String, appletId: String, _ completion: @escaping (IFTTTAppletResponse) -> Void) {
        Applet.Request.applet(id: appletId, forService: serviceId) { (response) in
            completion(IFTTTAppletResponse(response: response))
        }
        .start()
    }
    
    @objc public static func updateApplet(forService serviceId: String, appletId: String, isEnabled: Bool, _ completion: @escaping (IFTTTAppletResponse) -> Void) {
        Applet.Request.applet(id: appletId, forService: serviceId, setIsEnabled: isEnabled) { (response) in
            completion(IFTTTAppletResponse(response: response))
        }
        .start()
    }
}
