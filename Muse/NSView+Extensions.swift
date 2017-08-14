//
//  NSView+Extensions.swift
//  Muse
//
//  Created by Marco Albera on 12/08/2017.
//  Copyright © 2017 Edge Apps. All rights reserved.
//

import Cocoa

extension NSView {
    
    func toggleSubviewVisibilityAndResize(subview: NSView?, visible: Bool, animate: Bool = true) {
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

        if !animate {
            window.setContentSize(self.frame.size)
            window.shift(by: subview.frame.size.height, direction: visible ? .up : .down)
            return
        }
        
        NSAnimationContext.runAnimationGroup( { context in
            context.duration = 1/3
            context.allowsImplicitAnimation = true
            
            var frame = window.frame
            frame.origin.y    += visible ? -subview.frame.size.height : subview.frame.size.height
            frame.size.height -= visible ? -subview.frame.size.height : subview.frame.size.height
            window.setFrame(frame, display: true)
        }, completionHandler: { _ in
            if !visible { subview.removeFromSuperview() }
        })
    }
    
}
