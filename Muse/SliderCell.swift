//
//  SliderCell.swift
//  Muse
//
//  Created by Marco Albera on 01/12/16.
//  Copyright © 2016 Edge Apps. All rights reserved.
//

//  A slider cell with a custom knob image

import Cocoa

@available(OSX 10.12.1, *)
class SliderCell: NSSliderCell {
    
    let knobImage = NSImage(named: NSImageNameTouchBarPlayheadTemplate)
    
    override func drawKnob(_ knobRect: NSRect) {
        // Draw the knob
        guard let image = self.knobImage, let flipped = self.controlView?.isFlipped else {
            super.drawKnob(knobRect)
            return
        }
        
        let rect = self.knobRect(flipped: flipped)
        
        image.draw(in: rect, from: NSZeroRect, operation: .sourceOver, fraction: 1.0)
    }
    
    override func knobRect(flipped: Bool) -> NSRect {
        // Build the rect for our knob image
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
    
    func relativeKnobPosition() -> CGFloat {
        // Return current knob position %
        return CGFloat((self.doubleValue - self.minValue) / (self.maxValue - self.minValue))
    }
    
}
