//
//  TintedImage.swift
//  Muse
//
//  Created by Marco Albera on 21/08/2017.
//  Copyright © 2017 Edge Apps. All rights reserved.
//

import Cocoa

class NSTintedImage: NSImage {

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
        let tinted = NSTintedImage(cgImage: self.cgImage, size: self.size)
        
        tinted.tintColor = color
        
        // Image must not be template
        // otherwise system will override our tint
        tinted.isTemplate = false
        
        tinted.lockFocus()
        color.set()
        
        // Tint the image
        let imageRect = NSRect(origin: NSZeroPoint, size: self.size)
        NSRectFillUsingOperation(imageRect, .sourceAtop)
        
        tinted.unlockFocus()
        
        return tinted
    }
}

protocol TintableImageView: class {
        
    var image: NSImage? { get set }
}

extension TintableImageView {
    
    var tintColor: NSColor? {
        return tintedImage?.tintColor
    }
    
    var tintedImage: NSTintedImage? {
        return self.image as? NSTintedImage
    }
    
    var imagePreservingTint: NSImage? {
        set {
            if let color = tintColor {
                self.image = newValue?.tint(with: color)
            } else {
                self.image = newValue
            }
        }
        
        get {
            return self.image
        }
    }
}

extension NSImageView: TintableImageView { }

extension NSButton: TintableImageView { }
