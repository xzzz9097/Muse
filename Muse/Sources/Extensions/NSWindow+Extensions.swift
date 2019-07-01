//
//  NSWindow+Extensions.swift
//  Muse
//
//  Created by Marco Albera on 27/12/16.
//  Copyright © 2016 Edge Apps. All rights reserved.
//

enum NSWindowShiftDirection {
    case up
    case down
    case left
    case right
}

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
                self.level = NSWindow.Level.screenSaver
                self.hidesOnDeactivate = false
                self.orderFrontRegardless()
            } else {
                self.fadeClose(duration: 0.4) {
                    self.level = NSWindow.Level.normal
                    self.hidesOnDeactivate = true
                }
            }
        }
        
        get {
            return   self.level == NSWindow.Level.screenSaver &&
                    !self.hidesOnDeactivate
        }
    }
    
    func fadeClose(duration: TimeInterval,
                   completionHandler: @escaping () -> ()) {
        NSAnimationContext.runAnimationGroup( { context in
            context.duration = duration
            
            self.animator().alphaValue = 0.0
        }, completionHandler: {
            self.animator().alphaValue = 1.0
            completionHandler()
        } )
    }
    
    /**
     Shifts the origin of 'self' by a specified delta and direction, resizing self accordingly
     to keep original vertical and horizontal dimensions.
     - parameter value: the position shift delta
     - parameter direction: the direction the window will be shifted to (up, down, left or right)
     - parameter animate: when true applies an animation to the shift transition
     - parameter animationCompletionHandler: a closure to be run when the animation ends
     */
    func shift(by value: CGFloat,
               direction: NSWindowShiftDirection,
               animate: Bool = false,
               animationCompletionHandler: @escaping () -> () = { } ) {
        var frame = self.frame
        
        // Edit the frame basing on shift value and direction
        switch direction {
        case .up:
            frame.origin.y    -= value
            frame.size.height += value
        case .down:
            frame.origin.y    += value
            frame.size.height -= value
        case .left:
            frame.origin.x    -= value
            frame.size.width  += value
        case .right:
            frame.origin.x    += value
            frame.size.width  -= value
        }
        
        // If not animating immediately set the updated frame on the window
        if !animate {
            self.setFrame(frame, display: true, animate: false)
            return
        }
        
        // Run the frame update in an animation group if transition is requested
        NSAnimationContext.runAnimationGroup( { context in
            context.duration                = 1/3
            context.allowsImplicitAnimation = true
            
            self.setFrame(frame, display: true)
        }, completionHandler: { animationCompletionHandler() })
    }
    
}
