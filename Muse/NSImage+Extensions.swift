//
//  NSImage+Extensions.swift
//  Muse
//
//  Created by Marco Albera on 25/12/16.
//  Copyright © 2016 Edge Apps. All rights reserved.
//

@available(OSX 10.12.2, *)
extension NSImage {
    
    // MARK: Project drawables
    
    static let menuBarIcon  = NSImage(named: "menuBarIcon")!.forUI()
    
    static let shuffling    = NSImage(named: "DFRShuffle")!.forUI()
    static let repeating    = NSImage(named: "DFRRepeat")!.forUI()
    static let like         = NSImage(named: "DFRLike")!.forUI()
    static let liked        = NSImage(named: "DFRLiked")
    
    static let previous     = NSImage(named: NSImageNameTouchBarRewindTemplate)
    static let next         = NSImage(named: NSImageNameTouchBarFastForwardTemplate)
    static let play         = NSImage(named: NSImageNameTouchBarPlayTemplate)
    static let pause        = NSImage(named: NSImageNameTouchBarPauseTemplate)
    
    static let volumeLow    = NSImage(named: NSImageNameTouchBarAudioOutputVolumeLowTemplate)
    static let volumeMedium = NSImage(named: NSImageNameTouchBarAudioOutputVolumeMediumTemplate)
    static let volumeHigh   = NSImage(named: NSImageNameTouchBarAudioOutputVolumeHighTemplate)
    
    static let playhead     = NSImage(named: NSImageNameTouchBarPlayheadTemplate)
    static let playbar      = NSImage(named: "playbar")
    
    // MARK: Extended functions
    
    /**
     Returns the NSImage with 'isTemplate' enabled
     This lets the UI draw the appropriate color
     according to background (e.g. dark in TouchBar)
     */
    func forUI() -> NSImage {
        self.isTemplate = true
        
        return self
    }
    
    /**
     Returns the grayscale image tinted with the specified color
     http://stackoverflow.com/questions/1413135/tinting-a-grayscale-nsimage-or-ciimage
     - parameter color: the provided tint color
     - returns: tinted 'NSImage'
     */
    func tint(with color: NSColor) -> NSImage {
        guard let tinted = self.copy() as? NSImage else { return self }
        
        // Image must not be template
        // otherwise system will override our tint
        tinted.isTemplate = false
        
        tinted.lockFocus()
        color.set()
        
        // Tint the image
        let imageRect = NSRect(origin: NSZeroPoint, size: self.size)
        NSRectFillUsingOperation(imageRect, .sourceAtop)
        
        tinted.unlockFocus()
        
        return tinted
    }
}
