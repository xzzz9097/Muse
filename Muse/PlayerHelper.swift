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
    func trackDuration() -> Double?
    func scrub(to doubleValue: Double?, touching: Bool)
    
    /* Artwork */
    func artwork() -> Any?
    
    /* Callbacks */
    var trackChangedHandler: () -> () { set get }
    var timeChangedHandler: (Bool, Double?) -> () { set get }
    
    // The application identifier for the player
    static var bundleIdentifier: String { get }
    
    // ID for notification watcher
    var notificationID: String { get }
    
}
