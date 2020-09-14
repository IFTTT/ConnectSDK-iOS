//
//  Connection+Parsing.swift
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
        
        let activeTriggers = Connection.parseTriggers(parser)
        self.activeTriggers = activeTriggers
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
    
    static func parseTriggers(_ parser: Parser) -> Set<Trigger> {
        switch parser["user_connection"] {
        case .dictionary(let json):
            guard let userFeatures = json["user_features"] as? [JSON] else { return [] }
            let enabledUserFeatures = userFeatures.filter { dict -> Bool in
                guard let enabled = dict["enabled"] as? Bool else { return false }
                return enabled
            }
            
            let userFeatureTriggers = enabledUserFeatures.compactMap { $0["user_feature_triggers"] as? [JSON] }.reduce([], +)
            let allTriggers = userFeatureTriggers.compactMap { (userFeatureTrigger) -> [Trigger] in
                guard let userTriggerId = userFeatureTrigger["id"] as? String else { return [] }
                guard let userFields = userFeatureTrigger["user_fields"] as? [JSON] else { return [] }
                return userFields.compactMap { Trigger(json: $0, triggerId: userTriggerId) }
            }.reduce([], +)
            
            return Set(allTriggers)
        default:
            return []
        }
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

extension Connection.ConnectionStorage {
    private struct Keys {
        static let Id = "id"
        static let Status = "status"
        static let ActiveTriggers = "activeTriggers"
    }
    
    init(connection: Connection) {
        self.init(id: connection.id,
                  status: connection.status,
                  activeTriggers: connection.activeTriggers)
    }
    
    init?(json: JSON) {
        let parser = Parser(content: json)
        guard let id = parser[Keys.Id].string,
            let status = parser[Keys.Status].representation(of: Connection.Status.self) else { return nil }
        
        let triggers = parser[Keys.ActiveTriggers].compactMap { Trigger(parser: $0) }
        self.init(id: id,
                  status: status,
                  activeTriggers: Set(triggers))
    }
    
    func toJSON() -> JSON {
        let mappedTriggers = activeTriggers.map { $0.toJSON() }
        return [
            Keys.Id: id,
            Keys.Status: status.rawValue,
            Keys.ActiveTriggers: mappedTriggers
        ]
    }
}
