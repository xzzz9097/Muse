//
//  NSCustomizableButton.swift
//  Muse
//
//  Created by Marco Albera on 28/07/2017.
//  Copyright © 2017 Edge Apps. All rights reserved.
//

import Cocoa

class NSCustomizableButton: NSButton {
    
    var customizableCell: ButtonCell? {
        return self.cell as? ButtonCell
    }
    
    var fontSize: CGFloat? {
        didSet {
            if let size = fontSize {
                self.font = NSFont.systemFont(ofSize: size)
            }
        }
    }
    
    var textColor: NSColor? {
        didSet {
            if let color = textColor {
                customizableCell?.textColor = color
            }
        }
    }
    
    var hasRoundedLeadingImage: Bool? {
        didSet {
            if let roundedLeadingImage = hasRoundedLeadingImage {
                customizableCell?.hasRoundedLeadingImage = roundedLeadingImage
            }
        }
    }
    
    convenience init(title: String,
                     target: Any?,
                     action: Selector?,
                     hasRoundedLeadingImage: Bool) {
        self.init(title: title,
                  target: target,
                  action: action)
        
        self.hasRoundedLeadingImage = hasRoundedLeadingImage
    }
    
    override class func cellClass() -> AnyClass? {
        return ButtonCell.self
    }
    
}
