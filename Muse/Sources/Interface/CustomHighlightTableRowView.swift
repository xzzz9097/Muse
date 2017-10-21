//
//  CustomHighlightTableRowView.swift
//  Muse
//
//  Created by Marco Albera on 21/10/2017.
//  Copyright © 2017 Edge Apps. All rights reserved.
//

class CustomHighLightTableRowView: NSTableRowView {
    
    var fillColor: NSColor = .clear
    
    convenience init(fillColor: NSColor) {
        self.init()
        
        self.fillColor = fillColor
    }
    
    override func drawSelection(in dirtyRect: NSRect) {
        guard selectionHighlightStyle != .none else { return }
        
        fillColor.set()
        
        NSBezierPath.fill(bounds)
    }
}
