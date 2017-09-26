//
//  Double+Extensions.swift
//  Muse
//
//  Created by Marco Albera on 07/01/17.
//  Copyright © 2017 Edge Apps. All rights reserved.
//

import Foundation

/**
 Time intervals handling
 */
extension Double {
    
    // MARK: Extended functions
    
    /**
     Converts self (seconds in 'Double') to a tuple
     with an 'Int' for minutes and one for seconds
     */
    func secondsToMinutesAndSeconds() -> (Int, Int) {
        let minutes: Int = Int(self) / 60
        let seconds: Int = Int(self) % 60
        
        return (minutes, seconds)
    }
    
    /**
     Returns a 'String' formatted as MM:SS from self
     as a 'Double' of seconds
     */
    var secondsToMMSSString: String {
        let twoDigits = "%02d"
        
        // Get the values
        let (minutes, seconds) = secondsToMinutesAndSeconds()
        
        // This adds a leading zero when needed
        let minutesString = String(format: twoDigits, minutes)
        let secondsString = String(format: twoDigits, seconds)
        
        return "\(minutesString):\(secondsString)"
    }
    
}
