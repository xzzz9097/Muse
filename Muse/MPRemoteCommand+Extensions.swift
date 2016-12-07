//
//  MPRemoteCommand+Extensions.swift
//  Muse
//
//  Created by Marco Albera on 06/12/16.
//  Copyright © 2016 Edge Apps. All rights reserved.
//

import Foundation
import MediaPlayer

@available(OSX 10.12.1, *)
extension MPRemoteCommand {
    
    // Convenience function to simplify the activation
    // of the TouchBar button (aka MPRemoteCommand object)
    func activate(_ target: Any, action: Selector) {
        self.isEnabled = true
        
        self.addTarget(target, action: action)
    }
    
}
