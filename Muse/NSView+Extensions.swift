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
        guard   let subview = subview,
                let window = window else { return }
        
        let currentlyVisible = subview.isDescendant(of: self)
        
        // Check if requested visibility is actually different from current before proceeding
        guard visible != currentlyVisible else { return }
        
        if visible {
            // Show: only update frame size if we're not animating
            // but add the subview regardless to have a smooth entry animation
            if !animate { self.frame.size.height += subview.frame.size.height }
            self.addSubview(subview)
        } else if !animate {
            // Hide: only remove the subview and update view frame if we're not animating
            subview.removeFromSuperview()
            self.frame.size.height -= subview.frame.size.height
        }
        
        // Shift the window to the right position and, if animating, remove the subview
        // at the end of the transition to have it smoothly disappear
        window.shift(by: subview.frame.size.height,
                     direction: visible ? .up : .down,
                     animate: animate) { if !visible { subview.removeFromSuperview() } }
    }
    
}
