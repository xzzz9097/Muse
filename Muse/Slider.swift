//
//  Slider.swift
//  Muse
//
//  Created by Marco Albera on 22/06/2017.
//  Copyright © 2017 Edge Apps. All rights reserved.
//

import Cocoa

class Slider: NSSlider {
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
    }
    
    override func touchesBegan(with event: NSEvent) {
        
    }
    
    override func touchesEnded(with event: NSEvent) {
        
    }
    
    override func touchesMoved(with event: NSEvent) {
        
    }
    
    override func touchesCancelled(with event: NSEvent) {
        
    }
    
}
