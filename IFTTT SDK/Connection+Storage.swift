//
//  Connection+Storage.swift
//  IFTTT SDK
//
//  Created by Siddharth Sathyam on 9/8/20.
//  Copyright © 2020 IFTTT. All rights reserved.
//

import Foundation

extension Connection {
    final class ConnectionStorage: Hashable {
        let id: String
        let status: Status
        let activeTriggers: Set<Trigger>
        let activePermissions: Set<NativePermission>
        
        init(id: String,
             status: Status,
             activeTriggers: Set<Trigger>,
             activePermissions: Set<NativePermission>) {
            self.id = id
            self.status = status
            self.activeTriggers = activeTriggers
            self.activePermissions = activePermissions
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
        
        static func == (lhs: Connection.ConnectionStorage, rhs: Connection.ConnectionStorage) -> Bool {
            return lhs.id == rhs.id
        }
    }
}
