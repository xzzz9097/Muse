//
//  String+Extensions.swift
//  Muse
//
//  Created by Marco Albera on 28/12/16.
//  Copyright © 2016 Edge Apps. All rights reserved.
//

extension String {
    
    // MARK: Extended functions
    
    /*
     Returns a truncated NSString at the provided index
     NOTE: It's a non-mutating function, because it does
     not modify 'self' but an auxiliary 'truncated' string.
     So it works for both variable and constant strings
     */
    func truncate(at length: Int) -> String {
        guard self.count > length else { return self }
        
        // Split string till limited index
        var truncated = self.substring(to: self.index(self.startIndex, offsetBy: length))
        
        if truncated.last == " " {
            // Remove last character if it's a space
            truncated.removeLast()
        }
        
        // Append the 'wrap' symbol
        truncated = truncated.appending("...")
        
        // Return the truncated value
        return truncated
    }
    
}
