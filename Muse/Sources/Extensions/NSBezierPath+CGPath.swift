//
//  NSBezierPath+CGPath.swift
//  Muse
//
//  Created by Marco Albera on 02/10/2017.
//  Copyright © 2017 Edge Apps. All rights reserved.
//

extension NSBezierPath {
    
    static func circle(radius: CGFloat, center: NSPoint) -> NSBezierPath {
        let path = NSBezierPath()
        
        // Draw a full circle arc
        path.appendArc(withCenter: center,
                       radius:     radius,
                       startAngle: 0,
                       endAngle:   360)
        
        return path
    }
    
    /**
     Returns the CGPath from the current bezier path
     See https://stackoverflow.com/a/38860552
     */
    var cgPath: CGPath {
        let path = CGMutablePath()
        
        var points = [CGPoint](repeating: .zero, count: 3)
        
        for i in 0..<self.elementCount {
            let type = self.element(at: i, associatedPoints: &points)
            
            switch type {
            case .moveToBezierPathElement: path.move(to: points[0])
            case .lineToBezierPathElement: path.addLine(to: points[0])
            case .curveToBezierPathElement: path.addCurve(to: points[2],
                                                          control1: points[0],
                                                          control2: points[1])
            case .closePathBezierPathElement: path.closeSubpath()
            }
        }
        
        return path
    }
    
}
