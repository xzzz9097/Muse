//
//  SpotifyHelper.swift
//  Muse
//
//  Created by Marco Albera on 21/11/16.
//  Copyright © 2016 Edge Apps. All rights reserved.
//

import ScriptingBridge

// Protocol for Spotify application queries
// These props. and funcs. are set to optional in order
// to be overridded and implemented by the bridge itself
@objc fileprivate protocol SpotifyApplication {
    var isRunning: Bool { get }
    
    @objc optional var currentTrack: SpotifyTrack { get }
    @objc optional var playerPosition: Double { get }
    @objc optional var playerState: SpotifyEPlS { get }
    @objc optional var soundVolume: Int { get }
    @objc optional var repeating: Bool { get }
    @objc optional var shuffling: Bool { get }
    
    @objc optional func playpause()
    @objc optional func nextTrack()
    @objc optional func previousTrack()
    
    @objc optional func setPlayerPosition(_ position: Double)
    @objc optional func setSoundVolume(_ volume: Int)
    @objc optional func setRepeating(_ repeating: Bool)
    @objc optional func setShuffling(_ shuffling: Bool)
}

// Protocol for Spotify track object
@objc fileprivate protocol SpotifyTrack {
    @objc optional var name: String { get }
    @objc optional var artist: String { get }
    @objc optional var album: String { get }
    @objc optional var duration: Int { get }
    @objc optional var artworkUrl: String { get }
}

// Protocols will implemented and populated through here
extension SBApplication: SpotifyApplication { }

class SpotifyHelper: PlayerHelper {
    
    // Singleton constructor
    static let shared = SpotifyHelper()
    
    // The SBApplication object buond to the helper class
    private let application: SpotifyApplication = SBApplication.init(bundleIdentifier: BundleIdentifier)!
    
    // MARK: Player availability
    
    var isAvailable: Bool {
        // Returns if the application is running
        // ( implemented by SBApplication )
        return application.isRunning
    }
    
    // MARK: Player features
    
    let doesSendPlayPauseNotification = true
    
    // MARK: Song data
    
    var song: Song {
        guard let currentTrack = application.currentTrack else { return Song() }
        
        return Song(name: currentTrack.name!,
                    artist: currentTrack.artist!,
                    album: currentTrack.album!,
                    duration: trackDuration)
    }
    
    // MARK: Playback controls
    
    func togglePlayPause() {
        application.playpause!()
        
        execPlayPauseHandler()
    }
    
    func nextTrack() {
        application.nextTrack!()
        
        trackChangedHandler()
    }
    
    func previousTrack() {
        application.previousTrack!()
        
        trackChangedHandler()
    }
    
    // MARK: Playback status
    
    var isPlaying: Bool {
        let isPlaying = application.playerState == SpotifyEPlSPlaying
        
        // Return current playback status ( R/O )
        return isPlaying
    }
    
    var playbackPosition: Double {
        set {
            // Set the position on the player
            application.setPlayerPosition!(newValue)
        }
        
        get {
            guard let playbackPosition = application.playerPosition else { return 0 }
            
            // Return current playback position
            return playbackPosition
        }
    }
    
    var trackDuration: Double {
        guard   let currentTrack = application.currentTrack,
                let trackDuration = currentTrack.duration
        else { return 0 }
        
        // Return current track duration
        // It needs a cast because 'duration' from ScriptingBridge is Int
        return Double(trackDuration) / 1000
    }
    
    func scrub(to doubleValue: Double? = nil, touching: Bool = false) {
        if !touching, let value = doubleValue {
            playbackPosition = value * trackDuration
        }
        
        timeChangedHandler(touching, doubleValue)
    }
    
    // MARK: Playback options
    
    var volume: Int {
        set {
            // Set the volume on the player
            application.setSoundVolume!(newValue)
        }
        
        get {
            guard let volume = application.soundVolume else { return 0 }
            
            // Get current volume
            return volume
        }
    }
    
    var repeating: Bool {
        set {
            // Toggle repeating on the player
            application.setRepeating!(newValue)
            
            // Call the handler with new repeat value
            execShuffleRepeatChangedHandler()
        }
        
        get {
            guard let repeating = application.repeating else { return false }
            
            // Return current repeating status
            return repeating
        }
    }
    
    var shuffling: Bool {
        set {
            // Toggle shuffling on the player
            application.setShuffling!(newValue)
            
            // Call the handler with new shuffle value
            execShuffleRepeatChangedHandler()
        }
        
        get {
            guard let shuffling = application.shuffling else { return false }
            
            // Return current shuffling status
            return shuffling
        }
    }
    
    // MARK: Artwork
    
    func artwork() -> Any? {
        return application.currentTrack?.artworkUrl
    }
    
    // MARK: Callbacks
    
    var playPauseHandler: () -> () = { }
    
    var trackChangedHandler: () -> () = { }
    
    var timeChangedHandler: (Bool, Double?) -> () = { _, _ in }
    
    var shuffleRepeatChangedHandler: () -> () = { }
    
    // MARK: Application identifier
    
    static let BundleIdentifier = "com.spotify.client"
    
    // MARK: Notification ID
    
    static let TrackChangedNotification = BundleIdentifier + ".PlaybackStateChanged"
    
}
