//
//  NSView+Extensions.swift
//  Muse
//
//  Created by Marco Albera on 12/08/2017.
//  Copyright © 2017 Edge Apps. All rights reserved.
//

import Cocoa

extension NSView {
    
    func toggleSubviewVisibilityAndResize(subview: NSView?,
                                          visible: Bool,
                                          animate: Bool = true) {
        guard   let subview = subview,
                let window = window else { return }
        
        let currentlyVisible = subview.isDescendant(of: self)
        
        guard visible != currentlyVisible else { return }
        
        if visible {
            if !animate { self.frame.size.height += subview.frame.size.height }
            self.addSubview(subview)
        } else if !animate {
            subview.removeFromSuperview()
            self.frame.size.height -= subview.frame.size.height
        }
        
        window.shift(by: subview.frame.size.height,
                     direction: visible ? .up : .down,
                     animate: animate) { if !visible { subview.removeFromSuperview() } }
    }
    
}
