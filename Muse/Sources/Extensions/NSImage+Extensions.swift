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
    
    static let defaultBg    = NSImage(named: "DefaultBackground")!
    
    static let shuffling    = NSImage(named: "DFRShuffle")!.forUI()
    static let repeating    = NSImage(named: "DFRRepeat")!.forUI()
    static let like         = NSImage(named: "DFRLike")!.forUI()
    static let liked        = NSImage(named: "DFRLiked")
    
    static let previous     = NSImage(named: NSImageNameTouchBarRewindTemplate)!
    static let next         = NSImage(named: NSImageNameTouchBarFastForwardTemplate)!
    static let play         = NSImage(named: NSImageNameTouchBarPlayTemplate)!
    static let pause        = NSImage(named: NSImageNameTouchBarPauseTemplate)!
    
    static let volumeLow    = NSImage(named: NSImageNameTouchBarAudioOutputVolumeLowTemplate)
    static let volumeMedium = NSImage(named: NSImageNameTouchBarAudioOutputVolumeMediumTemplate)
    static let volumeHigh   = NSImage(named: NSImageNameTouchBarAudioOutputVolumeHighTemplate)
    
    static let playhead     = NSImage(named: NSImageNameTouchBarPlayheadTemplate)
    static let playbar      = NSImage(named: "playbar")
    
}

extension NSImage {
        
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
    
    func edit(size: NSSize? = nil,
              editCommand: @escaping (NSImage, NSSize) -> ()) -> NSImage {
        let temp = NSImage(size: size ?? self.size)
        
        guard temp.size.width > 0, temp.size.height > 0 else { return self }
        
        temp.lockFocus()
        editCommand(self, temp.size)
        temp.unlockFocus()
        
        return temp
    }
    
    /**
     Resizes NSImage
     - parameter newSize: the requested image size
     - parameter squareCrop: if true
     - returns: self scaled to requested size
     */
    func resized(to newSize: CGSize,
                 squareCrop: Bool = true,
                 marginCrop: CGFloat = 0.0) -> NSImage {
        return self.edit(size: newSize) {
            image, size in
            
            var fromRect = NSMakeRect(marginCrop,
                                      marginCrop,
                                      image.size.width  - 2 * marginCrop,
                                      image.size.height - 2 * marginCrop)
            let inRect   = NSMakeRect(0, 0, size.width, size.height)
            
            if squareCrop, image.size.width != image.size.height {
                let minSize = min(image.size.width, image.size.height)
                let maxSize = max(image.size.width, image.size.height)
                let start   = ( maxSize - minSize ) / 2
                
                fromRect = NSMakeRect(
                    image.size.width   != minSize ? start : 0,
                    image.size.height  != minSize ? start : 0,
                    minSize,
                    minSize
                )
            }
            
            image.draw(in:        inRect,
                       from:      fromRect,
                       operation: .sourceOver,
                       fraction:  1.0)
        }
    }
    
    /**
     Changes NSImage alpha
     - parameter alpha: the requested alpha value
     - returns: self with requested alpha value
     */
    func withAlpha(_ alpha: CGFloat) -> NSImage {
        return self.edit {
            image, size in
            image.draw(in: NSMakeRect(0, 0, size.width, size.height),
                       from: NSZeroRect,
                       operation: .sourceOver,
                       fraction: alpha)
        }
    }
    
}
