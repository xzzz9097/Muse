//
//  DispatchQueue+Extensions.swift
//  Muse
//
//  Created by Marco Albera on 30/12/16.
//  Copyright © 2016 Edge Apps. All rights reserved.
//

extension DispatchQueue {
    
    // MARK: Extended functions
    
    /*
     Convenience function for running a task after specified time
     work: the block of instructions to run
     millis: the delay in milliseconds
     */
    func run(_ work: @escaping @convention(block) () -> Swift.Void, after millis: Int) {
        self.asyncAfter(deadline: .now() + .milliseconds(millis), execute: work)
    }
    
}
