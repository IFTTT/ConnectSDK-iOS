//
//  NativeServices.swift
//  IFTTT SDK
//
//  Copyright © 2020 IFTTT. All rights reserved.
//

import Foundation
import CoreLocation

enum Trigger: Equatable, Hashable, CaseIterable {
    static var allCases: [Trigger] {
        return [
            .location(.init())
        ]
    }
    
    private struct Constants {
        static let LocationIdentifer = "location"
    }
    
    case location(CLCircularRegion)

    var identifier: String {
        switch self {
        case .location:
            return Constants.LocationIdentifer
        }
    }
    
    init?(json: JSON) {
        guard let fieldId = json["field_id"] as? String else { return nil }
        
        switch fieldId {
        case Constants.LocationIdentifer:
            guard let region = CLCircularRegion(json: json) else { return nil }
            self = .location(region)
        default:
            return nil
        }
    }
 
    func hash(into hasher: inout Hasher) {
        hasher.combine(identifier)
    }
    
    static func ==(lhs: Trigger, rhs: Trigger) -> Bool {
        return lhs.identifier == rhs.identifier
    }
}

enum NativePermission: CaseIterable, Equatable {
    case location
}

func ==(lhs: NativePermission, rhs: NativePermission) -> Bool {
    switch (lhs, rhs) {
    case (.location, .location):
        return true
    }
}

