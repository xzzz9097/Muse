//
//  ImageView.swift
//  Muse
//
//  Created by Marco Albera on 08/12/16.
//  Copyright © 2016 Edge Apps. All rights reserved.
//

import Cocoa

extension NSTrackingAreaOptions {
    
    // An OptionSet with the needed mouse tracking flags
    static var defaultMouse: NSTrackingAreaOptions {
        return [.mouseEnteredAndExited, .activeAlways]
    }
}

enum NSViewMouseHoverState {
    
    case entered
    case exited
}

class NSHoverableView: NSView {
    
    var mouseTrackingArea: NSTrackingArea!
    
    var onMouseHoverStateChange: ((NSViewMouseHoverState) -> ())?
    
    override func mouseEntered(with event: NSEvent) {
        onMouseHoverStateChange?(.entered)
    }
    
    override func mouseExited(with event: NSEvent) {
        onMouseHoverStateChange?(.exited)
    }
    
    override func updateTrackingAreas() {
        if let area = mouseTrackingArea {
            removeTrackingArea(area)
        }
        
        mouseTrackingArea = NSTrackingArea.init(rect: self.bounds,
                                                options: .defaultMouse,
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
}
