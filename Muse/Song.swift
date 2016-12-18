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
    var isPlaying: Bool
    var playbackPosition: Double // In milliseconds
    var duration: Double
    
    // MARK: Initializers
    
    init() {
        self.init(name: "",
                  artist: "",
                  album: "",
                  isPlaying: false,
                  playbackPosition: 0,
                  duration: 0)
    }
    
    init(name: String,
         artist: String,
         album: String,
         isPlaying: Bool,
         playbackPosition: Double,
         duration: Double) {
        self.name = name
        self.artist = artist
        self.album = album
        
        self.isPlaying = isPlaying
        
        self.playbackPosition = playbackPosition
        self.duration = duration
    }
    
}
