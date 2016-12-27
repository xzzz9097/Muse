//
//  Song.swift
//  Muse
//
//  Created by Marco Albera on 23/11/16.
//  Copyright © 2016 Edge Apps. All rights reserved.
//

import Foundation

struct Song {
    
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
    
}
