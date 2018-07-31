//
//  PlayerNotification.swift
//  Muse
//
//  Created by Marco Albera on 03/10/2017.
//  Copyright © 2017 Edge Apps. All rights reserved.
//

import Foundation

class PlayerNotification: InternalNotification<PlayerEvent>, Notificationable {
    
    static var name: Notification.Name {
        return Notification.Name("museHelperNotification")
    }
    
    static var notificationKey: String {
        return "helperNotification"
    }
}
