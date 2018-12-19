//
//  Connection_internal.swift
//  IFTTT SDK
//
//  Created by Jon Chmura on 10/29/18.
//  Copyright © 2018 IFTTT. All rights reserved.
//

import Foundation

extension Connection {
    init?(parser: Parser) {
        guard
            let id = parser["id"].string,
            let name = parser["name"].string,
            let description = parser["description"].string,
            let url = parser["url"].url
            else {
                return nil
        }
        self.id = id
        self.name = name
        self.description = description
        self.status = Status(rawValue: parser["user_status"].string ?? "") ?? .unknown
        self.services = parser["services"].compactMap { Service(parser: $0) }
        self.url = url
        guard let primaryService = services.first(where: { $0.isPrimary }) else {
            return nil
        }
        self.primaryService = primaryService
    }
    static func parseAppletsResponse(_ parser: Parser) -> [Connection]? {
        if let type = parser["type"].string {
            switch type {
            case "connection":
                if let applet = Connection(parser: parser) {
                    return [applet]
                }
            case "list":
                return parser["data"].compactMap { Connection(parser: $0) }
            default:
                break
            }
        }
        return nil
    }
}

extension Connection.Service {
    init?(parser: Parser) {
        guard
            let id = parser["service_id"].string,
            let name = parser["service_name"].string,
            let templateIconURL = parser["monochrome_icon_url"].url,
            let transparentBackgroundIconURL = parser["color_icon_url"].url,
            let brandColor = parser["brand_color"].color,
            let url = parser["url"].url else {
                return nil
        }
        self.id = id
        self.name = name
        self.isPrimary = parser["is_primary"].bool ?? false
        self.templateIconURL = templateIconURL
        self.standardIconURL = transparentBackgroundIconURL
        self.brandColor = brandColor
        self.url = url
    }
}
