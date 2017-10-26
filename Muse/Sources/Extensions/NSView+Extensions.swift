//
//  NSView+Extensions.swift
//  Muse
//
//  Created by Marco Albera on 12/08/2017.
//  Copyright © 2017 Edge Apps. All rights reserved.
//

import Cocoa

extension NSView {
    
    /**
     Hides or shows a subview of 'self' and resizes self and the window accordingly
     - parameter subviewHeight: the height of the view whose visibility will be toggled
     - parameter windowHeight: the height of the window without the subvuew
     - parameter visible: hide (false) or show (true) the view
     */
    func toggleSubviewVisibilityAndResize(subviewHeight: CGFloat,
                                          windowHeight: CGFloat,
                                          otherViewsHeight: [CGFloat] = [0],
                                          visible: Bool,
                                          completionHandler: @escaping () -> () = {}) {
        guard let window = window else { return }
        
        // Check input conditions: current window size and requested view visibility
        switch ( window.frame.size.height, visible ) {
        case ( windowHeight + subviewHeight, false ):
            // Window height is base + view's -> view is visible -> allow hiding (vis.: false)
            break
        case ( windowHeight + subviewHeight + otherViewsHeight.reduce(0, +), false ):
            // Consider other views present
            break
        case ( windowHeight + subviewHeight - otherViewsHeight.reduce(0, +), false ):
            // Or hidden
            break
        case ( windowHeight, true ):
            // Window height is base only -> view is hidden -> allow showing (vis.: true)
            break
        default:
            // Ignore any other cases, but evaluate completionHandler none the less
            completionHandler()
            return
        }
        
        var frame = window.frame
        
        // Increase frame height and shift it up to balance
        frame.size.height += visible ? subviewHeight : -subviewHeight
        frame.origin.y    -= visible ? subviewHeight : -subviewHeight
        
        // Run the animation at personalized speed
        NSAnimationContext.runAnimationGroup( { context in
            context.duration                = 1/3
            context.allowsImplicitAnimation = true
            
            window.setFrame(frame, display: true)
        } ) { completionHandler() }
    }
    
    /**
     Hides or shows a subview of 'self' and resizes self and the window accordingly
     - parameter subview: the view whose visibility will be toggled
     - parameter visible: hide (false) or show (true) the view
     - parameter animate: when true applies an animation to the hide/show transition
     - parameter completionHandler: a closure to be run at the end of toggling
     */
    func toggleSubviewVisibilityAndResize(subview: NSView?,
                                          visible: Bool,
                                          animate: Bool = true,
                                          completionHandler: @escaping () -> () = {}) {
        guard let subview = subview else { return }
        
        /*
    }*/
        
        let currentlyVisible = subview.isDescendant(of: self)
        
        // Check if requested visibility is actually different from current before proceeding
        guard visible != currentlyVisible else { return }
        
        if visible {
            // Show: only update frame size if we're not animating
            // but add the subview regardless to have a smooth entry animation
            switch subview.frame.origin.y {
            case 0.0:
                // The subview's origin is too far up
                // (e.g. it is first placed when view frame is in compressed mode)
                // so we shift it down
                subview.frame.origin.y -= subview.frame.size.height
            case -subview.frame.size.height:
                // The subview is arleady in the right origin, no need to move
                break
            default:
                // TODO: implement this case (stopping the whole action
                return
            }
            if !animate { self.frame.size.height += subview.frame.size.height }
            self.addSubview(subview)
        } else if !animate || window == nil {
            // Hide: only remove the subview and update view frame if we're not animating
            // or if window object is not ready yet (e.g. in viewDidLoad)
            subview.removeFromSuperview()
            self.frame.size.height -= subview.frame.size.height
            // Run the completion handler
            completionHandler()
        }
        
        // Shift the window to the right position and, if animating, remove the subview
        // at the end of the transition to have it smoothly disappear
        window?.shift(
            by: subview.frame.size.height,
            direction: visible ? .up : .down,
            animate: animate
        ) { // Finally remove subview for superview
            if !visible { subview.removeFromSuperview() }
            // Run the completion handler
            completionHandler() }
    }
}

extension NSView {
    
    func circleShaped(scale: CGFloat) {
        self.wantsLayer = true
        
        let radius = self.frame.size.width * scale
        let center = NSMakePoint(self.frame.size.width  / 2,
                                 self.frame.size.height / 2)
        
        self.layer?.maskToCircle(radius: radius, center: center)
    }
}
