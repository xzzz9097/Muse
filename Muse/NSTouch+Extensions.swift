//
//  NSTouch+Extensions.swift
//  Muse
//
//  Created by Marco Albera on 12/01/17.
//  Copyright © 2017 Edge Apps. All rights reserved.
//

@available(OSX 10.12.2, *)
extension NSTouch {
    
    // MARK: Extended variables
    
    // The maximum X treshold for considering
    // the touch out of bounds
    static let xBoundsThreshold: CGFloat = 25
    
    // MARK: Extended functions
    
    /**
     Determines whether a touch is going to go out of the bounds of a view,
     that is, if we are too close to its right or left margin.
     The margin size is defined in 'xBoundsThreshold'
     - parameter view: the view that we're touching
     - returns: if the touches are going out of the view
     */
    func isGoingOutOfXBounds(of view: NSView?) -> Bool {
        guard let view = view else { return false }
        
        return isGoingOutOfXLowerBound(of: view) || isGoingOutOfXUpperBound(of: view)
    }
    
    func isGoingOutOfXLowerBound(of view: NSView) -> Bool {
        return self.location(in: view).x < NSTouch.xBoundsThreshold
    }
    
    func isGoingOutOfXUpperBound(of view: NSView) -> Bool {
        return self.location(in: view).x > view.bounds.maxX - NSTouch.xBoundsThreshold
    }
    
}
