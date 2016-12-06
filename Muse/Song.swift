//
//  Song.swift
//  Muse
//
//  Created by Marco Albera on 23/11/16.
//  Copyright © 2016 Edge Apps. All rights reserved.
//

import Foundation

struct Song {
    
    // Basic song attributes
    var name: String
    var artist: String
    var album: String
    
    // Playing attributes
    var isPlaying: Bool
    var playbackPosition: Float // In milliseconds
    var duration: Float
    
    /* Initializers */
    init() {
        self.init(name: "", artist: "", album: "", isPlaying: false, playbackPosition: 0, duration: 0)
    }
    
    init(name: String, artist: String, album: String, isPlaying: Bool, playbackPosition: Float, duration: Float) {
        self.name = name
        self.artist = artist
        self.album = album
        
        self.isPlaying = isPlaying
        
        self.playbackPosition = playbackPosition
        self.duration = duration
    }
    
}
