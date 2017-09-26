//
//  NSTouch+Extensions.swift
//  Muse
//
//  Created by Marco Albera on 12/01/17.
//  Copyright © 2017 Edge Apps. All rights reserved.
//

@available(OSX 10.12.2, *)
extension NSTouch {
    
    // MARK: Extended functions
    
    /**
     Determines whether a touch is going to go out of the bounds of a view,
     that is, if we are too close to its right or left margin.
     - parameter view: the view that we're touching
     - parameter xThreshold: the x margin size
     - parameter yThreshold: the y margin size
     - returns: if the touches are going out of the view
     */
    func isGoingOutOfBounds(of view: NSView?, with xThreshold: CGFloat, _ yThreshold: CGFloat) -> Bool {
        guard let view = view else { return false }
        
        return  isGoingOutOfXBounds(of: view, with: xThreshold) ||
                isGoingOutOfYBounds(of: view, with: yThreshold)
    }
    
    func isGoingOutOfXBounds(of view: NSView, with threshold: CGFloat) -> Bool {
        return  isGoingOutOfXLowerBound(of: view, with: threshold) ||
                isGoingOutOfXUpperBound(of: view, with: threshold)
    }
    
    func isGoingOutOfYBounds(of view: NSView, with threshold: CGFloat) -> Bool {
        return  isGoingOutOfYLowerBound(of: view, with: threshold) ||
                isGoingOutOfXUpperBound(of: view, with: threshold)
    }
    
    func isGoingOutOfXLowerBound(of view: NSView, with threshold: CGFloat) -> Bool {
        return self.location(in: view).x < threshold
    }
    
    func isGoingOutOfXUpperBound(of view: NSView, with threshold: CGFloat) -> Bool {
        return self.location(in: view).x > view.bounds.maxX - threshold
    }
    
    func isGoingOutOfYLowerBound(of view: NSView, with threshold: CGFloat) -> Bool {
        return self.location(in: view).y > threshold
    }
    
    func isGoingOutOfYUpperBound(of view: NSView, with threshold: CGFloat) -> Bool {
        return self.location(in: view).y > view.bounds.maxY - threshold
    }
    
}
