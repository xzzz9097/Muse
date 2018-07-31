//
//  PreferenceNotification.swift
//  Muse
//
//  Created by Marco Albera on 30/07/2018.
//  Copyright © 2018 Edge Apps. All rights reserved.
//

import Foundation

class PreferenceNotification<T>: InternalNotification<Preference<T>>, Notificationable {
    
    static var name: Notification.Name {
        return Notification.Name("musePreferenceNotification")
    }
    
    static var notificationKey: String {
        return "preferenceNotification"
    }
}

