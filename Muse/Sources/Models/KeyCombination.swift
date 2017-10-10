//
//  KeyCombination.swift
//  Muse
//
//  Created by Marco Albera on 08/10/2017.
//  Copyright © 2017 Edge Apps. All rights reserved.
//

import Foundation

struct KeyCombination {
    
    let modifiers: NSEventModifierFlags?
    
    let keyCode: Int
    
    init(_ modifiers: NSEventModifierFlags, _ keyCode: uint16) {
        self.modifiers = modifiers
        self.keyCode   = Int(keyCode)
    }
    
    init(_ modifiers: NSEventModifierFlags, _ keyCode: Int) {
        self.modifiers = modifiers
        self.keyCode   = keyCode
    }
    
    init(_ keyCode: Int) {
        self.modifiers = nil
        self.keyCode   = keyCode
    }
}

func ~=(lhs: KeyCombination, rhs: KeyCombination) -> Bool {
    if let modifiers = lhs.modifiers {
        return rhs.modifiers?.contains(modifiers) ?? false && rhs.keyCode == lhs.keyCode
    }
    
    return rhs.keyCode == lhs.keyCode
}

