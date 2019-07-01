//
//  TintedImage.swift
//  Muse
//
//  Created by Marco Albera on 21/08/2017.
//  Copyright © 2017 Edge Apps. All rights reserved.
//

import Cocoa

class NSTintedImage: NSImage {

    // The tint color applied to the image
    // set when the NSTintedImage is created with NSImage.tint
    var tintColor: NSColor?
}

extension NSImage {
    
    /**
     Returns the grayscale image tinted with the specified color
     http://stackoverflow.com/questions/1413135/tinting-a-grayscale-nsimage-or-ciimage
     - parameter color: the provided tint color
     - returns: tinted 'NSImage'
     */
    func tint(with color: NSColor) -> NSTintedImage {
        // Dont't start from self.cgImage because it may scale incorrectly
        let tinted = NSTintedImage(size: self.size)
        
        // Save the tint color in the NSTintedImage object
        tinted.tintColor = color
        
        // Image must not be template
        // otherwise system will override our tint
        tinted.isTemplate = false
        
        // Lock the focus on the tinted image
        // so graphics will be draw in its context
        tinted.lockFocus()
        
        // First copy the current NSImage in the new tinted object
        let imageRect = NSRect(origin: NSZeroPoint,
                               size: self.size)
        self.draw(in: imageRect)
        
        // Then apply the tint
        color.set()
        imageRect.fill(using: .sourceAtop)
        
        tinted.unlockFocus()
        
        return tinted
    }
}

extension Imageable {
    
    // The tint color applied to the current tintedImage (if any)
    // We keep track of it to reapply the tint to new images as they're set
    var tintColor: NSColor? {
        return tintedImage?.tintColor
    }
    
    // The tinted image
    // retrieved by (optionally) casting the NSImage to NSTintedImage
    var tintedImage: NSTintedImage? {
        set {
            self.image = newValue
        }
        
        get {
            return self.image as? NSTintedImage
        }
    }
    
    /**
     Sets a new image applying the current color tint to it
     */
    func setImagePreservingTint(_ image: NSImage?) {
        if let color = tintColor {
            self.image = image?.tint(with: color)
        } else {
            self.image = image
        }
    }
}
