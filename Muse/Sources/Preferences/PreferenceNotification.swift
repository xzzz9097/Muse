//
//  PreferenceNotification.swift
//  Muse
//
//  Created by Marco Albera on 30/07/2018.
//  Copyright © 2018 Edge Apps. All rights reserved.
//

import Foundation

typealias PreferenceNotification<T> = InternalNotification<Preference<T>>

extension InternalNotification where T == Preference<Any> {
    
    var name: Notification.Name {
        return Notification.Name("musePreferenceNotification")
    }
    
    var notificationKey: String {
        return "preferenceNotification"
    }
    
}
