//
//  KeyCombination.swift
//  Muse
//
//  Created by Marco Albera on 08/10/2017.
//  Copyright © 2017 Edge Apps. All rights reserved.
//

import Foundation

struct KeyCombination {
    let modifiers: NSEvent.ModifierFlags?
    
    let keyCode: Int
    
    init(_ modifiers: NSEvent.ModifierFlags, _ keyCode: uint16) {
        self.modifiers = modifiers
        self.keyCode   = Int(keyCode)
    }
    
    init(_ modifiers: NSEvent.ModifierFlags, _ keyCode: Int) {
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

func ~=(lhs: Int, rhs: KeyCombination) -> Bool {
    return rhs.keyCode == lhs
}

typealias KeyCombinationTuple = (NSEvent.ModifierFlags, Int)

func ~=(lhs: KeyCombinationTuple, rhs: KeyCombinationTuple) -> Bool {
    return lhs.0 ~= rhs.0 && lhs.1 ~= rhs.1
}

func ~=(lhs: KeyCombinationTuple, rhs: KeyCombination) -> Bool {
    return rhs.modifiers?.contains(lhs.0) ?? false && rhs.keyCode == lhs.1
}
