//
//  Song.swift
//  Muse
//
//  Created by Marco Albera on 23/11/16.
//  Copyright © 2016 Edge Apps. All rights reserved.
//

import Foundation

struct Song: Equatable {
    
    // MARK: Song attributes
    
    var name: String
    var artist: String
    var album: String
    
    // MARK: Playing attributes
    
    var duration: Double // In 10^-3 s
    
    // MARK: Validation
    
    var isValid: Bool {
        // If the song has empty title
        // it should be invalidated
        return name != ""
    }
    
    /**
     Invalidates the song variable by reinitializing it
     */
    mutating func invalidate() {
        self = Song()
    }
    
    // MARK: Initializers
    
    init() {
        self.init(name: "", artist: "", album: "", duration: 0)
    }
    
    init(name: String, artist: String, album: String, duration: Double) {
        self.name = name
        self.artist = artist
        self.album = album
        self.duration = duration
    }
    
    // MARK: Equatable
    
    /**
     The equalization functions to conform to `Equatable` protocol.
     This allows to evaluate if two `Song` items are the same.
     */
    static func ==(lhs: Song, rhs: Song) -> Bool {
        return  lhs.name     == rhs.name   &&
                lhs.artist   == rhs.artist &&
                lhs.album    == rhs.album  &&
                lhs.duration == rhs.duration
    }
    
}
