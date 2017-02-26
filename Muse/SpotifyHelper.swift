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
    // Track properties
    @objc optional var currentTrack: SpotifyTrackProtocol { get }
    
    // Playback properties
    @objc optional var playerPosition: Double { get }
    @objc optional var playerState:    SpotifyEPlS { get }
    @objc optional var soundVolume:    Int { get }
    @objc optional var repeating:      Bool { get }
    @objc optional var shuffling:      Bool { get }
    
    // Playback control functions
    @objc optional func playpause()
    @objc optional func nextTrack()
    @objc optional func previousTrack()
    
    // Playback properties - setters
    @objc optional func setPlayerPosition(_ position: Double)
    @objc optional func setSoundVolume   (_ volume: Int)
    @objc optional func setRepeating     (_ repeating: Bool)
    @objc optional func setShuffling     (_ shuffling: Bool)
}

// Protocol for Spotify track object
@objc fileprivate protocol SpotifyTrackProtocol {
    @objc optional var name:       String { get }
    @objc optional var artist:     String { get }
    @objc optional var album:      String { get }
    @objc optional var duration:   Int { get }
    @objc optional var artworkUrl: String { get }
}

// Protocols will implemented and populated through here
extension SBApplication: SpotifyApplication { }

class SpotifyHelper: PlayerHelper {
    
    // Singleton constructor
    static let shared = SpotifyHelper()
    
    // The SBApplication object buond to the helper class
    private let application: SpotifyApplication? = SBApplication.init(bundleIdentifier: BundleIdentifier)
    
    // MARK: Player features
    
    let doesSendPlayPauseNotification = true
    
    let supportsStarring = false
    
    // MARK: Song data
    
    var song: Song {
        guard let application = application else { return Song() }
        
        guard let currentTrack = application.currentTrack else { return Song() }
        
        return Song(name: currentTrack.name!,
                    artist: currentTrack.artist!,
                    album: currentTrack.album!,
                    duration: trackDuration)
    }
    
    // MARK: Playback controls
    
    func togglePlayPause() {
        guard let application = application else { return }
        
        application.playpause!()
        
        execPlayPauseHandler()
    }
    
    func nextTrack() {
        guard let application = application else { return }
        
        application.nextTrack!()
        
        trackChangedHandler(true)
    }
    
    func previousTrack() {
        guard let application = application else { return }
        
        application.previousTrack!()
        
        trackChangedHandler(false)
    }
    
    // MARK: Playback status
    
    var playerState: PlayerState {
        guard let application = application else { return .stopped }
        
        // Return current playback status ( R/O )
        if application.playerState == SpotifyEPlSPlaying {
            return .playing
        } else if application.playerState == SpotifyEPlSPaused {
            return .paused
        } else if application.playerState == SpotifyEPlSStopped {
            return .stopped
        }
        
        // By default return stopped status
        return .stopped
    }
    
    var playbackPosition: Double {
        set {
            guard let application = application else { return }
            
            // Set the position on the player
            application.setPlayerPosition!(newValue)
        }
        
        get {
            guard let application = application else { return 0 }
            
            guard let playbackPosition = application.playerPosition else { return 0 }
            
            // Return current playback position
            return playbackPosition
        }
    }
    
    var trackDuration: Double {
        guard let application = application else { return 0 }
        
        guard   let currentTrack = application.currentTrack,
                let trackDuration = currentTrack.duration
        else { return 0 }
        
        // Return current track duration
        // It needs a cast because 'duration' from ScriptingBridge is Int
        return Double(trackDuration) / 1000
    }
    
    func scrub(to doubleValue: Double?, touching: Bool) {
        if !touching, let value = doubleValue {
            playbackPosition = value * trackDuration
        }
        
        timeChangedHandler(touching, doubleValue)
    }
    
    // MARK: Playback options
    
    var volume: Int {
        set {
            guard let application = application else { return }
            
            // Set the volume on the player
            application.setSoundVolume!(newValue)
        }
        
        get {
            guard let application = application else { return 0 }
            
            guard let volume = application.soundVolume else { return 0 }
            
            // Get current volume
            return volume
        }
    }
    
    var repeating: Bool {
        set {
            guard let application = application else { return }
            
            // Toggle repeating on the player
            application.setRepeating!(newValue)
            
            // Call the handler with new repeat value
            execShuffleRepeatChangedHandler(repeatChanged: true)
        }
        
        get {
            guard let application = application else { return false }
            
            guard let repeating = application.repeating else { return false }
            
            // Return current repeating status
            return repeating
        }
    }
    
    var shuffling: Bool {
        set {
            guard let application = application else { return }
            
            // Toggle shuffling on the player
            application.setShuffling!(newValue)
            
            // Call the handler with new shuffle value
            execShuffleRepeatChangedHandler(shuffleChanged: true)
        }
        
        get {
            guard let application = application else { return false }
            
            guard let shuffling = application.shuffling else { return false }
            
            // Return current shuffling status
            return shuffling
        }
    }
    
    // MARK: Artwork
    
    func artwork() -> Any? {
        guard let application = application else { return nil }
        
        return application.currentTrack?.artworkUrl
    }
    
    // MARK: Callbacks
    
    var playPauseHandler: () -> () = { }
    
    var trackChangedHandler: (Bool) -> () = { _ in }
    
    var timeChangedHandler: (Bool, Double?) -> () = { _, _ in }
    
    var shuffleRepeatChangedHandler: (Bool, Bool) -> () = { _, _ in }
    
    // MARK: Application identifier
    
    static let BundleIdentifier = "com.spotify.client"
    
    // MARK: Notification ID
    
    static let rawTrackChangedNotification = BundleIdentifier + ".PlaybackStateChanged"
    
}
