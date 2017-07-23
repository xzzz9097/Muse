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
    
    func setVisibility(_ visible: Bool, animateClose: Bool = false) {
        // Toggles window visibility
        // Bringing the older app on top if necessary
        if visible {
            self.makeKeyAndOrderFront(self)
            NSApp.activate(ignoringOtherApps: true)
        } else {
            if animateClose {
                // Fade out animation on window close
                NSAnimationContext.beginGrouping()
                NSAnimationContext.current().duration = 0.4
                NSAnimationContext.runAnimationGroup(
                { _ in self.animator().alphaValue = 0.0 }
                ) {
                    self.animator().alphaValue = 1.0
                    NSApp.hide(self)
                }
                NSAnimationContext.endGrouping()
            } else {
                NSApp.hide(self)
            }
        }
    }
    
}
