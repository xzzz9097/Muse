//
//  NSWindow+Extensions.swift
//  Muse
//
//  Created by Marco Albera on 27/12/16.
//  Copyright © 2016 Edge Apps. All rights reserved.
//

extension NSWindow {
    
    // MARK: Extended functions
    
    func toggleVisibility() {
        // Hide window if focused, show if not
        setVisibility(!self.isKeyWindow)
    }
    
    func setVisibility(_ visible: Bool) {
        // Toggles window visibility
        // Bringing the older app on top if necessary
        if visible {
            self.makeKeyAndOrderFront(self)
            NSApp.activate(ignoringOtherApps: true)
        } else {
            NSApp.hide(self)
        }
    }
    
}
