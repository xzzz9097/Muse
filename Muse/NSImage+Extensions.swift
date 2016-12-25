//
//  NSImage+Extensions.swift
//  Muse
//
//  Created by Marco Albera on 25/12/16.
//  Copyright © 2016 Edge Apps. All rights reserved.
//

extension NSImage {
    
    // Returns the NSImage with 'isTemplate' enabled
    // This lets the UI draw the appropriate color
    // according to background (e.g. dark in TouchBar)
    func forUI() -> NSImage {
        self.isTemplate = true
        
        return self
    }
    
}
