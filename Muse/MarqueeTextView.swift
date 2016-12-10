//
//  MarqueeTextView.swift
//  Muse
//
//  Created by Marco Albera on 08/12/16.
//  Copyright © 2016 Edge Apps. All rights reserved.
//

import Cocoa

class MarqueeTextView: NSView {
    
    var scroller = Timer()
    
    var point: NSPoint = NSZeroPoint
    
    var speed: TimeInterval = 0.0
    
    var stringWidth: CGFloat = 0.0
    
    private var _stringValue = ""
    var stringValue: String {
        get {
            return self._stringValue
        }
        
        set(value) {
            self._stringValue = value
            
            self.point = NSZeroPoint
            
            self.stringWidth = (value as NSString).size(withAttributes: nil).width
            
            if speed > 0 && !scroller.isValid {
                self.scroller = createScroller(with: self.speed)
            }
        }
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        let string = _stringValue as NSString

        if point.x + stringWidth < 0 {
            point.x += dirtyRect.size.width
        }
        
        string.draw(at: point, withAttributes: nil)
        
        if point.x < 0 {
            var newPoint = point
            
            newPoint.x += dirtyRect.size.width
            
            string.draw(at: newPoint, withAttributes: nil)
        }
    }
    
    func createScroller(with speed: TimeInterval) -> Timer {
        return Timer.scheduledTimer(timeInterval: speed,
                                    target: self,
                                    selector: #selector(scrollText),
                                    userInfo: nil,
                                    repeats: true)
    }
    
    func scrollText() {
        point.x -= 1.0
        
        self.needsDisplay = true
    }
    
    deinit {
        scroller.invalidate()
    }
    
}
