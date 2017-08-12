//
//  NSView+Extensions.swift
//  Muse
//
//  Created by Marco Albera on 12/08/2017.
//  Copyright © 2017 Edge Apps. All rights reserved.
//

import Cocoa

extension NSView {
    
    func toggleSubviewVisibilityAndResize(subview: NSView?, visible: Bool) {
        guard let subview = subview, let window = window else { return }
        
        if visible {
            self.addSubview(subview)
            self.frame.size.height += subview.frame.size.height
        } else {
            subview.removeFromSuperview()
            self.frame.size.height -= subview.frame.size.height
        }
        
        window.setContentSize(self.frame.size)
        
        window.shift(by: subview.frame.size.height, direction: visible ? .up : .down)
    }
    
}
