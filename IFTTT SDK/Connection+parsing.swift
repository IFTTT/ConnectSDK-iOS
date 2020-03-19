//
//  Connection_internal.swift
//  IFTTT SDK
//
//  Copyright © 2019 IFTTT. All rights reserved.
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
        
        self.coverImages = CoverImage.images(with: parser["cover_image"])
        
        self.valuePropositionsParser = parser["value_propositions"]
        
        self.features = parser["features"].compactMap {
            Connection.Feature(parser: $0)
        }
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
            let shortName = parser["service_short_name"].string,
            let templateIconURL = parser["monochrome_icon_url"].url,
            let brandColor = parser["brand_color"].color,
            let url = parser["url"].url else {
                return nil
        }
        self.id = id
        self.name = name
        self.shortName = shortName
        self.isPrimary = parser["is_primary"].bool ?? false
        self.templateIconURL = templateIconURL
        self.brandColor = brandColor
        self.url = url
    }
}

private extension Connection.Feature {
    init?(parser: Parser) {
        guard
            let title = parser["title"].string,
            let iconURL = parser["icon_url"].url else {
                return nil
        }
        self.details = parser["description"].string
        self.title = title
        self.iconURL = iconURL
    }
}

private extension Connection.CoverImage {
    static func images(with parser: Parser) -> [Connection.CoverImage.Size : Connection.CoverImage] {
        let images: [Connection.CoverImage] = Size.all.compactMap {
            if let url = parser["\($0.rawValue)w_url"].url {
                return Connection.CoverImage(url: url, size: $0)
            } else {
                return nil
            }
        }
        return images.reduce(into: [Connection.CoverImage.Size : Connection.CoverImage]()) { (dict, image) in
            dict[image.size] = image
        }
    }
}
