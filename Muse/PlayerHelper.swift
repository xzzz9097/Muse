//
//  PlayerHelper.swift
//  Muse
//
//  Created by Marco Albera on 29/11/16.
//  Copyright © 2016 Edge Apps. All rights reserved.
//

protocol PlayerHelper: class {
    
    // Create song data
    var song: Song { get }
    
    /* Control functions */
    func togglePlayPause()
    func nextTrack()
    func previousTrack()
    
    /* Playback status functions */
    func currentPlaybackPosition() -> Double?
    func goTo(time: Double)
    
    /* Artwork */
    func artwork() -> Any?
    
    // The application identifier for the player
    static var bundleIdentifier: String { get }
    
    // ID for notification watcher
    var notificationID: String { get }
    
}
