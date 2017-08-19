//
//  ImageView.swift
//  Muse
//
//  Created by Marco Albera on 08/12/16.
//  Copyright © 2016 Edge Apps. All rights reserved.
//

import Cocoa

class NSHoverableView: NSView {
    
    // Tracking area variable
    var mouseTrackingArea: NSTrackingArea!
    
    // Clousure for mouseEntered and mouseExited callbacks
    // Will be set after initialization (e.g. in ViewController)
    var mouseHandler: ((Bool) -> Void)!

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
    }
    
    /* Mouse entered function with its callback */
    override func mouseEntered(with event: NSEvent) {
        if let handler = mouseHandler {
            handler(true)
        }
    }
    
    /* Mouse exited function with its callback */
    override func mouseExited(with event: NSEvent) {
        if let handler = mouseHandler {
            handler(false)
        }
    }
    
    /* Tracking area initialization */
    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        
        guard mouseTrackingArea == nil else {
            removeTrackingArea(mouseTrackingArea)
            return
        }
        
        mouseTrackingArea = NSTrackingArea.init(rect: self.bounds,
                                                options: mouseTrackingOptions(),
                                                owner: self,
                                                userInfo: nil)
        
        self.addTrackingArea(mouseTrackingArea)
    }

    func refreshMouseTrackingArea() {
        if let area = mouseTrackingArea {
            removeTrackingArea(area)
        }
        
        mouseTrackingArea = nil
    }
    
    /* Return an OptionSet with the needed mouse tracking flags */
    func mouseTrackingOptions() -> NSTrackingAreaOptions {
        return [.mouseEnteredAndExited, .activeAlways]
    }
    
}
