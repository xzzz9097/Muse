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
                self.fadeClose(duration: 0.4) { NSApp.hide(self) }
            } else {
                NSApp.hide(self)
            }
        }
    }
    
    var isVisibleAsHUD: Bool {
        set {
            if newValue {
                self.level = NSScreenSaverWindowLevel
                self.hidesOnDeactivate = false
                self.orderFrontRegardless()
            } else {
                self.fadeClose(duration: 0.4) {
                    self.level = NSNormalWindowLevel
                    self.hidesOnDeactivate = true
                }
            }
        }
        
        get {
            return   self.level == NSScreenSaverWindowLevel &&
                    !self.hidesOnDeactivate
        }
    }
    
    func fadeClose(duration: TimeInterval,
                   completionHandler: @escaping () -> ()) {
        NSAnimationContext.current().duration = duration
        
        NSAnimationContext.beginGrouping()
        NSAnimationContext.runAnimationGroup(
            { _ in self.animator().alphaValue = 0.0 },
            completionHandler:
            {      self.animator().alphaValue = 1.0
                   completionHandler() }
        )
        NSAnimationContext.endGrouping()
    }
    
}
