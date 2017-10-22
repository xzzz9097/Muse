//
//  KeySensitiveTableView.swift
//  Muse
//
//  Created by Marco Albera on 22/10/2017.
//  Copyright © 2017 Edge Apps. All rights reserved.
//

import Cocoa

import Carbon.HIToolbox

class KeySensitiveTableView: NSTableView {
    
    // Block executed when return key is pressed
    // if the table if first responder
    var returnAction: ((KeySensitiveTableView) -> ())?
    
    /**
     Intercept key events performed while the table is first responder.
     For our purpuoses we discard all events except ⏎, ⬆ and ⬇
     */
    override func keyDown(with event: NSEvent) {
        switch KeyCombination(event.modifierFlags, event.keyCode) {
        case kVK_Return:
            // Execute return block
            self.returnAction?(self)
        case kVK_UpArrow, kVK_DownArrow:
            // Call super for arrow keys
            // This retains up/down navigation
            super.keyDown(with: event)
        default: return // Ditch all other keycodes
        }
    }
    
    /**
     Prevent tableView from becoming first responder.
     It will only programmatically receive keyDown(_:) events from textField.
     */
    override func becomeFirstResponder() -> Bool {
        return false
    }
}
