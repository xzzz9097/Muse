//
//  ButtonCell.swift
//  Muse
//
//  Created by Marco Albera on 05/01/17.
//  Copyright © 2017 Edge Apps. All rights reserved.
//

import Cocoa

class ButtonCell: NSButtonCell {
    
    // MARK: Properties
    
    // Radius of the rounded NSImage
    var radius: CGFloat = 5.0 {
        didSet {
            self.controlView?.needsDisplay = true
        }
    }
    
    // Amount by which the title label will be moved
    var xOriginShiftDelta: CGFloat = -5.0 {
        didSet {
            self.controlView?.needsDisplay = true
        }
    }

    // MARK: Drawing functions
    
    /**
     Creates the image at the very beginning of the button
     */
    override func imageRect(forBounds rect: NSRect) -> NSRect {
        return NSMakeRect(0, 0, rect.height, rect.height)
    }
    
    /**
     Draws the title at a new position to suit new image origin
     */
    override func drawTitle(_ title: NSAttributedString, withFrame frame: NSRect, in controlView: NSView) -> NSRect {
        var frame = frame
        
        // Shift the title leftwards
        // TODO: Calculate this more accurately
        frame.origin.x += xOriginShiftDelta
        
        return super.drawTitle(title, withFrame: frame, in: controlView)
    }
    
    /**
     Draws the requested NSImage in a rounded rect
     */
    override func drawImage(_ image: NSImage, withFrame frame: NSRect, in controlView: NSView) {
        NSGraphicsContext.saveGraphicsState()
        
        let path = NSBezierPath(roundedRect: frame, xRadius: radius, yRadius: radius)
        path.addClip()
        
        image.size = frame.size
        
        image.draw(in: frame, from: NSZeroRect, operation: .sourceOver, fraction: 1.0, respectFlipped: true, hints: nil)
        
        NSGraphicsContext.restoreGraphicsState()
    }
    
}
