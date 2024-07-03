//
//  Connection+Parsing.swift
//  IFTTT SDK
//
//  Copyright © 2019 IFTTT. All rights reserved.
//

import Foundation

extension Connection {
    convenience init?(parser: Parser) {
        guard
            let id = parser["id"].string,
            let name = parser["name"].string,
            let description = parser["description"].string,
            let url = parser["url"].url
            else {
                return nil
        }

        let services = parser["services"].compactMap { Service(parser: $0) }
        guard let primaryService = services.first(where: { $0.isPrimary }) else {
            return nil
        }
        
        let status = Status(rawValue: parser["user_status"].string ?? "") ?? .unknown
        let coverImages = CoverImage.images(with: parser["cover_image"])
        
        let valuePropositionsParser = parser["value_propositions"]

        let features = parser["features"].compactMap {
            Connection.Feature(parser: $0)
        }
        
        let activeUserTriggers = Connection.parseTriggers(parser)
        
        self.init(
            id: id, 
            name: name, 
            details: description,
            status: status, 
            url: url,
            coverImages: coverImages,
            valuePropositionsParser: valuePropositionsParser,
            features: features,
            services: services,
            primaryService: primaryService, 
            activeUserTriggers: activeUserTriggers
        )
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

        self.triggers = Set(parser["feature_triggers"].compactMap { innerParser -> Trigger? in
            let fieldsParser = innerParser["fields"]
            let foundParser = fieldsParser.first(where: { parser -> Bool in
                guard let id = parser["id"].string else { return false }
                return Trigger.supportedTriggerId(id)
            })
            guard let id = innerParser["id"].string,
                  let foundParser = foundParser else { return nil }
            
            return Trigger(defaultFieldParser: foundParser, triggerId: id)
        })
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
        static let AllTriggers = "allTriggers"
        static let EnabledNativeServiceMap = "enabledNativeServiceMap"
    }
    
    init(connection: Connection) {
        self.init(id: connection.id,
                  status: connection.status,
                  activeUserTriggers: connection.activeUserTriggers,
                  allTriggers: connection.allNativeTriggers,
                  enabledNativeServiceMap: [.location: true])
    }
    
    init?(json: JSON) {
        let parser = Parser(content: json)
        guard let id = parser[Keys.Id].string,
            let status = parser[Keys.Status].representation(of: Connection.Status.self) else { return nil }
        
        let activeUserTriggers = parser[Keys.ActiveTriggers].compactMap { Trigger(parser: $0) }
        let allTriggers = parser[Keys.AllTriggers].compactMap { Trigger(parser: $0) }
        
        var map = [Connection.NativeServiceDescription: Bool]()
        switch parser[Keys.EnabledNativeServiceMap] {
        case .dictionary(let json):
            Connection.NativeServiceDescription.allCases.forEach { (description) in
                if let boolValue = json[description.rawValue] as? Bool {
                    map[description] = boolValue
                }
            }
        default:
            break
        }
        
        self.init(id: id,
                  status: status,
                  activeUserTriggers: Set(activeUserTriggers),
                  allTriggers: Set(allTriggers),
                  enabledNativeServiceMap: map)
    }
    
    func toJSON() -> JSON {
        let mappedAllTriggers = allTriggers.map { $0.toJSON() }
        let mappedActiveUserTriggers = activeUserTriggers.map { $0.toJSON() }
        let mappedEnabledNativeServiceMap: [String: Bool] = enabledNativeServiceMap.reduce(into: [:]) { result, x in
            result[x.key.rawValue] = x.value
        }

        return [
            Keys.Id: id,
            Keys.Status: status.rawValue,
            Keys.ActiveTriggers: mappedActiveUserTriggers,
            Keys.AllTriggers: mappedAllTriggers,
            Keys.EnabledNativeServiceMap: mappedEnabledNativeServiceMap
        ]
    }
}
