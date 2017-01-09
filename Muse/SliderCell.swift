//
//  SliderCell.swift
//  Muse
//
//  Created by Marco Albera on 01/12/16.
//  Copyright © 2016 Edge Apps. All rights reserved.
//

//  A slider cell with a custom knob image

import Cocoa

class SliderCell: NSSliderCell {
    
    // MARK: Properties
    // These require resreshing after being set
    // through calling needsDisplay on the control view
    // aka 'NSSliderView'
    
    // The NSImage resource for the knob
    var knobImage: NSImage! {
        didSet {
            self.controlView?.needsDisplay = true
        }
    }
    
    // The knob's visibility
    var knobVisible: Bool = true {
        didSet {
            self.controlView?.needsDisplay = true
        }
    }
    
    // Colors
    var backgroundColor = NSColor.lightGray.withAlphaComponent(0.5) {
        didSet {
            self.controlView?.needsDisplay = true
        }
    }
    var highlightColor  = NSColor.darkGray {
        didSet {
            self.controlView?.needsDisplay = true
        }
    }
    
    // Roundness radius
    var radius: CGFloat = 1 {
        didSet {
            self.controlView?.needsDisplay = true
        }
    }
    
    // Height
    var height: CGFloat = 2.5 {
        didSet {
            self.controlView?.needsDisplay = true
        }
    }
    
    // Time info switch
    var hasTimeInfo: Bool = false {
        didSet {
            // Without this there's graphic corruption
            // on the drawn string
            self.controlView?.needsDisplay = true
        }
    }
    
    // Time info
    var timeInfo: NSString = ""
    
    /**
     Draw the bars, setting custom height, colors and radius
     */
    override func drawBar(inside rect: NSRect, flipped: Bool) {
        var backgroundRect = rect
        var leftRect       = rect
        
        // Apply the desired heigt
        backgroundRect.size.height = height
        leftRect.size.height       = height
        
        // Center the slider
        backgroundRect.origin.y = rect.midY - height / 2.0
        leftRect.origin.y       = backgroundRect.origin.y
        
        leftRect.size.width *= relativeKnobPosition()
        
        // Create the drawing areas
        let backgroundColorArea = NSBezierPath(roundedRect: backgroundRect, xRadius: radius, yRadius: radius)
        let highlightColorArea  = NSBezierPath(roundedRect: leftRect, xRadius: radius, yRadius: radius)
        
        // Fill the background area
        backgroundColor.setFill()
        backgroundColorArea.fill()
        
        // Fill the active area
        highlightColor.setFill()
        highlightColorArea.fill()
    }
    
    /**
     Draw the knob
     */
    override func drawKnob(_ knobRect: NSRect) {
        guard   let image = self.knobImage,
                let flipped = self.controlView?.isFlipped
        else {
            super.drawKnob(knobRect)
            return
        }
        
        let rect = self.knobRect(flipped: flipped)
        
        // Determine wheter the knob will be visible
        let fraction: CGFloat = knobVisible ? 1.0 : 0.0
        
        image.draw(in: rect, from: NSZeroRect, operation: .sourceOver, fraction: fraction)
        
        if hasTimeInfo { drawInfo(near: rect) }
    }
    
    /**
     Build the rect for our knob image
     */
    override func knobRect(flipped: Bool) -> NSRect {
        guard let image = self.knobImage, var bounds = self.controlView?.bounds else {
            return super.knobRect(flipped: flipped)
        }
        
        var rect = super.knobRect(flipped: flipped)
        
        rect.size = image.size
        
        bounds = NSInsetRect(bounds, ceil(rect.size.width / 2), 0)

        let absKnobPosition = self.relativeKnobPosition() * NSWidth(bounds) + NSMinX(bounds);
        
        rect = NSOffsetRect(rect, absKnobPosition - NSMidX(rect) + 1, 0)
        
        return rect
    }
    
    /**
     Return current knob position %
     */
    func relativeKnobPosition() -> CGFloat {
        return CGFloat((self.doubleValue - self.minValue) / (self.maxValue - self.minValue))
    }
    
    /**
     Draws the specified 'timeInfo' text near the knob
     */
    func drawInfo(near knobRect: NSRect) {
        timeInfo.draw(in: infoRect(near: knobRect), withAttributes: infoFontAttributes)
    }
    
    /**
     Returns a rect near the knob for the info view
     */
    func infoRect(near knobRect: NSRect) -> NSRect {
        var rect = knobRect
        
        // Sets dimensions the rect
        // TODO: Adapt this to given text
        let margin = CGFloat(20)
        let width  = CGFloat(35) + margin
        let height = CGFloat(20)
        
        rect.size.width  = width
        rect.size.height = height
        
        // Set correct position (left or right the knob, centered vertically)
        rect.origin.x += rect.origin.x > width ? -width : margin
        rect.origin.y  = knobRect.midY - height / 2.0
        
        return rect
    }
    
    /**
     Font attributes for the info text
     */
    var infoFontAttributes: [String: Any] {
        let size  = CGFloat(17)
        let color = NSColor.lightGray
        
        let font  = NSFont.systemFont(ofSize: size)
        
        return [NSFontAttributeName: font,
                NSForegroundColorAttributeName: color]
    }
    
}
