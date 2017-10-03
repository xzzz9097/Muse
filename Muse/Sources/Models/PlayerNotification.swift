//
//  PlayerNotification.swift
//  Muse
//
//  Created by Marco Albera on 03/10/2017.
//  Copyright © 2017 Edge Apps. All rights reserved.
//

import Foundation

struct PlayerNotification {
    
    static private let name = Notification.Name("museHelperNotification")
    
    static private let helperNotificationKey = "helperNotification"
    
    // The event associated with the notification
    let event: PlayerEvent
    
    init(_ event: PlayerEvent) {
        self.event = event
    }
    
    /**
     Posts the notification of the specified event
     */
    func post() {
        NotificationCenter.default.post(
            name: PlayerNotification.name,
            object: nil,
            userInfo: [PlayerNotification.helperNotificationKey: self])
    }
    
    /**
     Sets up an observer for the specified event
     executing the given closure
     */
    static func observe(block: @escaping (PlayerEvent) -> ()) {
        NotificationCenter.default.addObserver(
            forName: name,
            object: nil,
            queue: nil)
        { notification in
            if let helperNotification = notification.userInfo?[helperNotificationKey] as? PlayerNotification {
                block(helperNotification.event)
            }
        }
    }
}
