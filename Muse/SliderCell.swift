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
    
    // The NSImage resource for the knob
    var knobImage: NSImage!
    
    // The knob's visibility
    var knobVisible: Bool = true
    
    /*
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
    }
    
    /*
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
    
    /*
     Return current knob position %
     */
    func relativeKnobPosition() -> CGFloat {
        return CGFloat((self.doubleValue - self.minValue) / (self.maxValue - self.minValue))
    }
    
}
