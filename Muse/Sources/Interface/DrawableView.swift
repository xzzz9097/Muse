//
//  DrawableView.swift
//  Muse
//
//  Created by Marco Albera on 25/07/2018.
//  Copyright © 2018 Edge Apps. All rights reserved.
//

import Cocoa

typealias DrawableViewShape     = DrawableView.Shape
typealias DrawableViewShapePath = DrawableView.ShapePath

class DrawableView: NSView {
    
    enum Shape {
        case line
    }
    
    struct ShapePath {
        var startPoint: NSPoint
        var endPoint:   NSPoint
        
        /**
         Returns a prebuilt path for a line in a view, with requested margin
         */
        static func forCheckLineIn(_ view: DrawableView,
                                   margin: CGFloat) -> ShapePath {
            let size = view.frame.size
            
            return ShapePath(startPoint: NSMakePoint(margin, margin),
                             endPoint:   NSMakePoint(size.width  - margin,
                                                     size.height - margin))
        }
    }
    
    // Master switch for shape drawing
    var shouldDrawShape = false {
        didSet {
            // Redraw the view when requested
            self.needsDisplay = true
        }
    }
    
    // The shape to draw
    var shape: Shape = .line
    
    // The color of the shape
    var shapeColor: NSColor = .black
    
    // The path of the shape
    var shapePath: ShapePath?
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        // Draw our shape
        if shouldDrawShape { drawShape() }
    }
    
    /**
     Draws the requested shape on the view. Called during draw(_)
     */
    func drawShape() {
        guard let shapePath = shapePath else { return }
        
        switch shape {
        case .line:
            drawLine(color: shapeColor, path: shapePath)
        }
    }
    
    /**
     Draws a line with requested parameters
     */
    func drawLine(color: NSColor, path: ShapePath) {
        color.set()
        
        let line = NSBezierPath()
        
        line.move(to: path.startPoint)
        line.line(to: path.endPoint)
        
        line.lineWidth = 2.0
        
        line.stroke()
    }
}
