//
//  Animations.swift
//  Muse
//
//  Created by Marco Albera on 04/01/17.
//  Copyright © 2017 Edge Apps. All rights reserved.
//

extension CALayer {
    
    // MARK: Keypaths
    
    static let kBackgroundColorPath = "backgroundColor"
    
    // MARK: Extendes functions
    
    /**
     Animates a value change for whatever property in a CALayer.
     - paramater value: the new value to set
     - parameter key: the keypath of the property to modify
     */
    func animateChange(to value: Any?, for key: String) {
        let animation = CABasicAnimation(keyPath: key)
        
        // Lock the transaction
        // Should avoid layer corruption
        CATransaction.lock()
        
        CATransaction.begin()
        
        // Callback for actually setting the new value
        // when the animation ends
        CATransaction.setCompletionBlock {
            self.setValue(value, forKey: key)
        }
        
        animation.toValue = value
        
        // Also to avoid flickering
        animation.isRemovedOnCompletion = false
        animation.fillMode = kCAFillModeForwards
        
        self.add(animation, forKey: key)
        
        CATransaction.commit()
        
        CATransaction.unlock()
    }
    
}

extension CAShapeLayer {
    
    static func circleLayerMask(radius: CGFloat, center: NSPoint) -> CAShapeLayer {
        let layer = CAShapeLayer()
        
        layer.path = NSBezierPath.circle(radius: radius, center: center).cgPath
        
        return layer
    }
}

extension CALayer {
    
    func maskToCircle(radius: CGFloat, center: NSPoint) {
        self.mask = CAShapeLayer.circleLayerMask(radius: radius, center: center)
    }
}
