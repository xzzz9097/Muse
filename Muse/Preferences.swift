//
//  Preferences.swift
//  Muse
//
//  Created by Marco Albera on 28/07/2017.
//  Copyright © 2017 Edge Apps. All rights reserved.
//

import Cocoa

typealias PreferenceKey = Preference.Key

struct Preference {
    
    let userDefaults = UserDefaults.standard
    
    let key: PreferenceKey
    
    enum Key: String {
        
        typealias RawValue = String
        
        case peekToolbarsOnHover = "peekToolbarsOnHover"
        
        case menuBarTitle = "menuBarTitle"
        
        case controlStripItem = "controlStripItem"
        
        case controlStripHUD = "controlStripHUD"
        
        var name: RawValue {
            return rawValue
        }
        
    }
    
    init(_ key: PreferenceKey) {
        self.key = key
    }
    
    func set(_ value: Any) {
        userDefaults.set(value, for: key)
    }
    
    var value: Any? {
        return userDefaults.object(for: key)
    }
    
    static let defaults: [PreferenceKey: Any] = [.peekToolbarsOnHover: true,
                                                 .menuBarTitle:        true,
                                                 .controlStripItem:    true,
                                                 .controlStripHUD:     true]
    
    static func registerDefaults() {
        UserDefaults.standard.register(defaults: defaults.userDefaultsCompatible)
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
