//
//  CustomHighlightTableRowView.swift
//  Muse
//
//  Created by Marco Albera on 21/10/2017.
//  Copyright © 2017 Edge Apps. All rights reserved.
//

class CustomHighLightTableRowView: NSTableRowView {
    
    // The custom highlight selection color
    var fillColor: NSColor?
    
    convenience init(fillColor: NSColor?) {
        self.init()
        
        self.fillColor = fillColor
    }
    
    /**
     Override drawSelection to paint a custom highlight fill in the selected row
     */
    override func drawSelection(in dirtyRect: NSRect) {
        guard selectionHighlightStyle != .none, let fillColor = fillColor else { return }
        
        fillColor.set()
        
        // Fill the row rect (bounds) with the custom highlight color
        NSBezierPath.fill(bounds)
    }
}
