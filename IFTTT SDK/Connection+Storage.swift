//
//  Connection+Storage.swift
//  IFTTT SDK
//
//  Copyright © 2020 IFTTT. All rights reserved.
//

import Foundation

extension Connection {
    struct ConnectionStorage: Hashable {
        let id: String
        let status: Status
        let activeTriggers: Set<Trigger>
        
        init(id: String,
             status: Status,
             activeTriggers: Set<Trigger>) {
            self.id = id
            self.status = status
            self.activeTriggers = activeTriggers
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
        
        static func == (lhs: Connection.ConnectionStorage, rhs: Connection.ConnectionStorage) -> Bool {
            return lhs.id == rhs.id
        }
    }
}
