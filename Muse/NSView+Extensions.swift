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
     - parameter subview: the view whose visibility will be toggled
     - parameter visible: hide (false) or show (true) the view
     - parameter animate: when true applies an animation to the hide/show transition
     */
    func toggleSubviewVisibilityAndResize(subview: NSView?,
                                          visible: Bool,
                                          animate: Bool = true) {
        guard let subview = subview else { return }
        
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
        }
        
        // Shift the window to the right position and, if animating, remove the subview
        // at the end of the transition to have it smoothly disappear
        window?.shift(by: subview.frame.size.height,
                      direction: visible ? .up : .down,
                      animate: animate) { if !visible { subview.removeFromSuperview() } }
    }
    
}
