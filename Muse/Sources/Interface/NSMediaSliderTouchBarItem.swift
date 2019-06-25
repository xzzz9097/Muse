//
//  NSMediaSliderTouchBarItem.swift
//  Alamofire
//
//  Created by Marco Albera on 26/07/2017.
//

import Cocoa

@available(OSX 10.12.2, *)
class NSMediaSliderTouchBarItem: NSSliderTouchBarItem {
    
    override init(identifier: NSTouchBarItem.Identifier) {
        super.init(identifier: identifier)
        
        prepareSlider()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        prepareSlider()
    }
    
    func prepareSlider() {
        let slider      = Slider()
        let cell        = SliderCell()

        cell.isTouchBar               = true
        slider.cell                   = cell
        
        // TODO: find a way to remove this
        slider.wantsLayer             = true
        slider.layer?.backgroundColor = NSColor.black.cgColor
        
        self.slider = slider
    }
    
}
