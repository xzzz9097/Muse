//
//  Slider.swift
//  Muse
//
//  Created by Marco Albera on 22/06/2017.
//  Copyright © 2017 Edge Apps. All rights reserved.
//

import Cocoa

class Slider: NSSlider {
    
    weak var delegate: SliderDelegate?
    
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
        super.touchesBegan(with: event)
        
        delegate?.didTouchesBegan()
    }
    
    override func touchesMoved(with event: NSEvent) {
        super.touchesMoved(with: event)
        
        delegate?.didTouchesMoved()
    }
    
    override func touchesEnded(with event: NSEvent) {
        super.touchesEnded(with: event)
        
        delegate?.didTouchesEnd()
    }
    
    override func touchesCancelled(with event: NSEvent) {
        super.touchesCancelled(with: event)
    }
    
}

protocol SliderDelegate: class {
    func didTouchesBegan()
    func didTouchesMoved()
    func didTouchesEnd()
}
