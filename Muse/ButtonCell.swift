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
    
    // Has custom image drawing
    var hasRoundedLeadingImage = false {
        didSet {
            self.controlView?.needsDisplay = true
        }
    }
    
    // Radius of the rounded NSImage
    var radius: CGFloat = 5.0 {
        didSet {
            self.controlView?.needsDisplay = true
        }
    }
    
    var textColor = NSColor.alternateSelectedControlTextColor {
        didSet {
            self.controlView?.needsDisplay = true
        }
    }
    
    let imageRectOriginDelta: CGFloat = -8.0
    
    var computeImageRectOriginDelta = false {
        didSet {
            self.controlView?.needsDisplay = true
        }
    }
    
    var titleMarginWithRoundedLeadingImage: CGFloat = 2.0 {
        didSet {
            self.controlView?.needsDisplay = true
        }
    }
    
    // Amount by which the title label will be moved
    var xOriginShiftDelta: CGFloat {
        // Only reduce the margin if we have an image
        guard   let view = self.controlView,
                hasRoundedLeadingImage,
                self.image != nil else { return 0 }
        
        if !computeImageRectOriginDelta {
            return imageRectOriginDelta + titleMarginWithRoundedLeadingImage
        }
        
        // Compute the delta based on our rect vs super's
        return  imageRect(forBounds: view.bounds).origin.x       -
                super.imageRect(forBounds: view.bounds).origin.x +
                titleMarginWithRoundedLeadingImage
    }

    // MARK: Drawing functions
    
    override func drawingRect(forBounds rect: NSRect) -> NSRect {
        guard hasRoundedLeadingImage else { return super.drawingRect(forBounds: rect) }
        
        return super.drawingRect(forBounds: NSMakeRect(rect.origin.x,
                                                       rect.origin.y,
                                                       rect.size.width - xOriginShiftDelta,
                                                       rect.size.height))
    }
    
    override func titleRect(forBounds rect: NSRect) -> NSRect {
        guard hasRoundedLeadingImage else { return super.drawingRect(forBounds: rect) }
        
        return super.titleRect(forBounds: rect.insetBy(dx: xOriginShiftDelta, dy: 0))
    }
    
    /**
     Creates the image at the very beginning of the button
     */
    override func imageRect(forBounds rect: NSRect) -> NSRect {
        return hasRoundedLeadingImage ? NSMakeRect(0, 0, rect.height, rect.height) :
                                        super.imageRect(forBounds: rect)
    }
    
    /**
     Draws the title at a new position to suit new image origin
     */
    override func drawTitle(_ title: NSAttributedString, withFrame frame: NSRect, in controlView: NSView) -> NSRect {
        var frame = frame
        
        // Shift the title leftwards
        if hasRoundedLeadingImage { frame.origin.x += xOriginShiftDelta }
        
        let string = NSMutableAttributedString(attributedString: title)
        string.addAttribute(NSForegroundColorAttributeName,
                            value: textColor,
                            range: NSMakeRange(0, string.length))
        
        return super.drawTitle(string, withFrame: frame, in: controlView)
    }
    
    /**
     Draws the requested NSImage in a rounded rect
     */
    override func drawImage(_ image: NSImage, withFrame frame: NSRect, in controlView: NSView) {
        guard hasRoundedLeadingImage else { return super.drawImage(image,
                                                                   withFrame: frame,
                                                                   in: controlView)}
        
        NSGraphicsContext.saveGraphicsState()
        
        let path = NSBezierPath(roundedRect: frame, xRadius: radius, yRadius: radius)
        path.addClip()
        
        image.size = frame.size
        
        image.draw(in: frame, from: NSZeroRect, operation: .sourceOver, fraction: 1.0, respectFlipped: true, hints: nil)
        
        NSGraphicsContext.restoreGraphicsState()
    }
    
}
