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
    
    // The color fill for the knob
    var knobColor: NSColor? {
        didSet {
            self.controlView?.needsDisplay = true
        }
    }
    
    // The knob's width
    var knobWidth: CGFloat? {
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
    
    // The knob's left and right margin
    var knobMargin: CGFloat = 2.0 {
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
    
    // Width
    var width: CGFloat? {
        didSet {
            self.controlView?.needsDisplay = true
        }
    }
    
    // Bar fill margin fraction
    // min: 0 - max: 0.5
    // adds a fraction * height margin to left bar fill
    var fillMarginFraction: CGFloat = 0.0 {
        didSet {
            // Make sure we're not over max value
            if fillMarginFraction > 0.5 { fillMarginFraction = 0.5 }
            
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
    let paraghraphStyle = NSMutableParagraphStyle()
    
    var infoFontLeftColor: NSColor = .lightGray {
        didSet {
            self.controlView?.needsDisplay = true
        }
    }
    
    var infoFontRightColor: NSColor = .lightGray {
        didSet {
            self.controlView?.needsDisplay = true
        }
    }
    
    var infoFontSize: CGFloat = 17.0 {
        didSet {
            self.controlView?.needsDisplay = true
        }
    }
    
    // TouchBar slider properties
    private let barStep:  CGFloat = 2
    private let barWidth: CGFloat = 1
    private let barFill           = NSColor.labelColor.withAlphaComponent(0.25)
    
    /**
     Draw the bars, setting custom height, colors and radius
     */
    override func drawBar(inside rect: NSRect, flipped: Bool) {
        var backgroundRect = rect
        var leftRect       = rect
        
        // Apply the desired height, with a padding around fill if requested
        backgroundRect.size.height = height
        leftRect.size.height       = height - ( fillMarginFraction * height )
        
        // Center the slider
        backgroundRect.origin.y = rect.midY - height / 2.0
        leftRect.origin.y       = rect.midY - leftRect.size.height / 2.0
        
        leftRect.size.width *= relativeKnobPosition()
        
        // Draw TouchBar slider
        // Inspired by https://github.com/lhc70000/iina
        if isTouchBar {
            barFill.setFill()
            
            // Draw the vertical bars in the background rect
            ( 0 ..< Int( backgroundRect.width / barStep ) + 1 )
                .map { CGFloat($0) * barStep }
                .forEach { NSBezierPath(rect: NSRect(x: backgroundRect.origin.x + $0,
                                                     y: backgroundRect.origin.y,
                                                     width: barWidth,
                                                     height: backgroundRect.height)).fill() }
            
            return
        }
        
        // Fill the bars
        [ ( backgroundRect, backgroundColor ), ( leftRect, highlightColor ) ].forEach {
            $1.setFill()
            
            // Draw in the correct area with specified radius
            NSBezierPath(roundedRect: $0,
                         xRadius: radius,
                         yRadius: radius).fill()
        }
    }
    
    /**
     Draw the knob
     */
    override func drawKnob(_ knobRect: NSRect) {
        if hasTimeInfo { drawInfo(near: knobRect) }
        
        if let color = knobColor {
            color.drawSwatch(in: knobRect)
            return
        }
        
        if let image = knobImage {
            // Determine wheter the knob will be visible
            let fraction: CGFloat = knobVisible ? 1.0 : 0.0
            
            image.draw(in: knobRect,
                       from: NSZeroRect,
                       operation: .sourceOver,
                       fraction: fraction)
            return
        }
        
        super.drawKnob(knobRect)
    }
    
    /**
     Build the main cell rect with specified width
     */
    override func barRect(flipped: Bool) -> NSRect {
        if let width = width {
            var rect = super.barRect(flipped: flipped)
            
            // Center the rect
            rect.origin.x  -= ( width - rect.width ) / 2
            // Set new size
            rect.size.width = width
            
            return rect
        }
        
        return super.barRect(flipped: flipped)
    }
    
    /**
     Build the rect for our knob image
     */
    override func knobRect(flipped: Bool) -> NSRect {
        // Only run this if knob width or img is custom
        guard   var bounds = self.controlView?.bounds, (knobImage != nil || knobWidth != nil)
            else { return super.knobRect(flipped: flipped) }
        
        var rect = super.knobRect(flipped: flipped)
        
        if let image = knobImage {
            rect.size = image.size
        } else if let width = knobWidth {
            rect.size.width = width
        }
        
        bounds = NSInsetRect(bounds, rect.size.width + knobMargin, 0)
        
        let absKnobPosition = self.relativeKnobPosition() * NSWidth(bounds) + NSMinX(bounds);
        
        rect = NSOffsetRect(rect, absKnobPosition - NSMidX(rect), 0)
        
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
        let isLeftOfKnob = shouldInfoBeLeft(of: rect)
        
        paraghraphStyle.alignment = isLeftOfKnob ? .left : .right
        
        return [NSAttributedStringKey.font.rawValue: NSFont.systemFont(ofSize: infoFontSize),
                NSAttributedStringKey.foregroundColor.rawValue: isLeftOfKnob ? infoFontLeftColor : infoFontRightColor,
                NSAttributedStringKey.paragraphStyle.rawValue: paraghraphStyle]
    }
    
}
