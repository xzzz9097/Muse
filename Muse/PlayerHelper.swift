//
//  PlayerHelper.swift
//  Muse
//
//  Created by Marco Albera on 29/11/16.
//  Copyright © 2016 Edge Apps. All rights reserved.
//

protocol PlayerHelper: class {
    
    // MARK: Song data
    
    var song: Song { get }
    
    // MARK: Playback controls
    
    func togglePlayPause()
    
    func nextTrack()
    
    func previousTrack()
    
    // MARK: Playback status
    
    func currentPlaybackPosition() -> Double?
    
    func trackDuration() -> Double?
    
    func scrub(to doubleValue: Double?, touching: Bool)
    
    // MARK: Artwork
    
    func artwork() -> Any?
    
    // MARK: Callbacks
    
    var trackChangedHandler: () -> () { set get }
    
    var timeChangedHandler: (Bool, Double?) -> () { set get }
    
    // MARK: Application identifier
    
    static var bundleIdentifier: String { get }
    
    // MARK: Notification ID
    
    var notificationID: String { get }
    
}
