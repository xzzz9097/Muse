//
//  Preferences.swift
//  Muse
//
//  Created by Marco Albera on 28/07/2017.
//  Copyright © 2017 Edge Apps. All rights reserved.
//

import Cocoa

enum PreferenceKey: String {
    
    case peekToolbarsOnHover = "peekToolbarsOnHover"
    
    case menuBarTitle = "menuBarTitle"
    
    case controlStripItem = "controlStripItem"
    
    case controlStripHUD = "controlStripHUD"
    
    var name: RawValue {
        return rawValue
    }
    
    var defaultValue: Any {
        return PreferenceKey.defaults[self]!
    }
    
    static let defaults: [PreferenceKey: Any] = [.peekToolbarsOnHover: true,
                                                 .menuBarTitle:        true,
                                                 .controlStripItem:    true,
                                                 .controlStripHUD:     true]
    
    static func registerDefaults() {
        UserDefaults.standard.register(defaults: defaults.userDefaultsCompatible)
    }
    
}

protocol Preferenceable {
    
    associatedtype ValueType
    
    var key: PreferenceKey { get }
    
}

extension Preferenceable {
    
    var userDefaults: UserDefaults {
        return UserDefaults.standard
    }
    
    var value: ValueType {
        return userDefaults.object(for: key) as? ValueType ?? defaultValue
    }
    
    func set(_ value: ValueType) {
        userDefaults.set(value, for: key)
    }
    
    var defaultValue: ValueType {
        return key.defaultValue as! ValueType
    }
    
}

struct Preference<T>: Preferenceable {

    typealias ValueType = T
    
    var key: PreferenceKey
    
    init (_ key: PreferenceKey) {
        self.key = key
    }
    
}

extension Dictionary where Key == PreferenceKey {
    
    var userDefaultsCompatible: [String: Any] {
        var dictionary: [String: Any] = [:]
        
        for (key, value) in zip(self.keys.map { $0.name }, self.values) {
            dictionary[key] = value
        }
        
        return dictionary
    }
    
}

extension UserDefaults {
    
    func set(_ value: Any, for preferenceKey: PreferenceKey) {
        set(value, forKey: preferenceKey.name)
    }
    
    func object(for preferenceKey: PreferenceKey) -> Any? {
        return object(forKey: preferenceKey.name)
    }
    
}
