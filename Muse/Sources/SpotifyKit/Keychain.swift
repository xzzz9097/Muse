//
//  Keychain.swift
//  SpotifyKit
//
//  Created by Marco Albera on 19/09/2017.
//

import Foundation
import Security

struct Keychain {
    
    typealias KeychainItem = [NSString: AnyObject]
    
    let service = Bundle.main.bundleIdentifier!
    
    static let standard = Keychain()
    
    public func data(forKey key: String) -> Data? {
        var getQuery = query(forKey: key)
        
        getQuery[kSecMatchLimit] = kSecMatchLimitOne
        getQuery[kSecReturnData] = true as AnyObject?
    
        var dataRef: CFTypeRef?
        
        SecItemCopyMatching(getQuery as CFDictionary, &dataRef)
        
        return dataRef as? Data
    }
    
    func value(forKey key: String) -> Any? {
        guard let data = data(forKey: key) else { return nil }
        
        return NSKeyedUnarchiver.unarchiveObject(with: data)
    }
    
    func setData(_ object: Data, forKey key: String) {
        var setQuery = query(forKey: key)
        
        var update = KeychainItem()
        
        update[kSecValueData] = object as AnyObject
        
        if data(forKey: key) != nil {
            SecItemUpdate(setQuery as CFDictionary, update as CFDictionary)
        } else {
            update.forEach { (key, value) in setQuery[key] = value }
            
            SecItemAdd(setQuery as CFDictionary, nil)
        }
    }
    
    func set(_ object: Any, forKey key: String) {
        let data = NSKeyedArchiver.archivedData(withRootObject: object)
        
        setData(data, forKey: key)
    }
    
    func query(forKey key: String) -> KeychainItem {
        var query = KeychainItem()
        
        query[kSecAttrService] = service as AnyObject
        
        query[kSecClass] = kSecClassGenericPassword
        
        query[kSecAttrAccount] = key as AnyObject
        query[kSecAttrGeneric] = key as AnyObject
        
        return query
    }
}
