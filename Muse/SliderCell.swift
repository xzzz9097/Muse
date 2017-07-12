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
    
    // TouchBar mode switch
    var isTouchBar: Bool = false {
        didSet {
            if isTouchBar, #available(OSX 10.12.2, *) {
                knobImage       = .playhead
                height          = 20
                radius          = 0
            } else if isTouchBar {
                isTouchBar = false
            }
        }
    }
    
    // Time info
    var timeInfo: NSString = ""
    
    // Info bar sizes
    let infoHeight: CGFloat = 20.0
    let infoWidth:  CGFloat = 70.0
    
    // Info bar font attributes
    let infoColor       = NSColor.lightGray
    let infoFont        = NSFont.systemFont(ofSize: 17)
    let paraghraphStyle = NSMutableParagraphStyle()
    
    // TouchBar slider properties
    private let barStep:  CGFloat = 2
    private let barWidth: CGFloat = 1
    
    /**
     Draw the bars, setting custom height, colors and radius
     */
    override func drawBar(inside rect: NSRect, flipped: Bool) {
        var backgroundRect = rect
        var leftRect       = rect
        
        // Apply the desired height, with a 15% padding around fill
        backgroundRect.size.height = height
        leftRect.size.height       = height - min(0.15 * height, 0.5)
        
        // Center the slider
        backgroundRect.origin.y = rect.midY - height / 2.0
        leftRect.origin.y       = rect.midY - leftRect.size.height / 2.0
        
        leftRect.size.width *= relativeKnobPosition()
        
        // Draw TouchBar slider
        // (heavily) inspired by https://github.com/lhc70000/iina
        if isTouchBar {
            NSGraphicsContext.saveGraphicsState()
            
            NSBezierPath(roundedRect: backgroundRect, xRadius: 0, yRadius: 0).setClip()
            let end = backgroundRect.width
            
            NSColor.labelColor.withAlphaComponent(0.25).setFill()
            
            var i: CGFloat = 0.0
            while (i < end + barStep) {
                let dest = NSRect(x: backgroundRect.origin.x + i,
                                  y: backgroundRect.origin.y,
                                  width: barWidth,
                                  height: backgroundRect.height)
                
                NSBezierPath(rect: dest).fill()
                i += barStep
            }
            
            NSGraphicsContext.restoreGraphicsState()
            
            return
        }
        
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
        guard let flipped = self.controlView?.isFlipped else {
            super.drawKnob(knobRect)
            return
        }
        
        let rect = self.knobRect(flipped: flipped)
        
        if hasTimeInfo { drawInfo(near: rect) }
        
        guard let image = self.knobImage else {
            super.drawKnob(knobRect)
            return
        }
        
        // Determine wheter the knob will be visible
        let fraction: CGFloat = knobVisible ? 1.0 : 0.0
        
        image.draw(in: rect, from: NSZeroRect, operation: .sourceOver, fraction: fraction)
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
        timeInfo.draw(in: infoRect(near: knobRect),
                      withAttributes: infoFontAttributes(for: knobRect))
    }
    
    /**
     Returns a rect near the knob for the info view
     */
    func infoRect(near knobRect: NSRect) -> NSRect {
        var rect = knobRect
        
        // Sets dimensions the rect
        // TODO: Adapt this to given text
        rect.size.width  = infoWidth + knobRect.width
        rect.size.height = height
        
        // Set correct position (left or right the knob, centered vertically)
        rect.origin.x += shouldInfoBeLeft(of: knobRect) ? -infoWidth : 0
        rect.origin.y  = knobRect.midY - height / 2.0
        
        return rect
    }
    
    /**
     Determines whether info view should be drawn on lhs or rhs,
     based on space availability before the knob rect
     */
    func shouldInfoBeLeft(of knobRect: NSRect) -> Bool {
        return knobRect.origin.x > infoWidth
    }
    
    /**
     Font attributes for the info text
     */
    func infoFontAttributes(for rect: NSRect) -> [String: Any] {
        paraghraphStyle.alignment = shouldInfoBeLeft(of: rect) ? .left : .right
        
        return [NSFontAttributeName: infoFont,
                NSForegroundColorAttributeName: infoColor,
                NSParagraphStyleAttributeName: paraghraphStyle]
    }
    
}
