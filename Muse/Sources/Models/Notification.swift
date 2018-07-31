//
//  Notification.swift
//  Muse
//
//  Created by Marco Albera on 30/07/2018.
//  Copyright © 2018 Edge Apps. All rights reserved.
//

import Foundation

protocol Notificationable {
    
    associatedtype EventType
    
    static var name: Notification.Name { get }
    
    static var notificationKey: String { get }
    
    var event: EventType { set get }
}

struct InternalNotification<T>: Notificationable {
    
    typealias EventType = T
    
    static var name: Notification.Name {
        return Notification.Name("")
    }
    
    static var notificationKey: String {
        return ""
    }
    
    var event: EventType
    
    init(_ event: EventType) {
        self.event           = event
    }
}

extension Notificationable {
    
    /**
     Posts the notification of the specified event
     */
    func post() {
        NotificationCenter.default.post(
            name: Self.name,
            object: nil,
            userInfo: [Self.notificationKey: event])
    }
    
    /**
     Sets up an observer for the specified event
     executing the given closure
     */
    static func observe(block: @escaping (EventType) -> ()) {
        NotificationCenter.default.addObserver(
            forName: Self.name,
            object: nil,
            queue: nil)
        { notification in
            if let event = notification.userInfo?[Self.notificationKey] as? EventType {
                block(event)
            }
        }
    }
}
