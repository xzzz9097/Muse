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
@objc protocol SpotifyApplication: class {
    @objc optional var currentTrack: SpotifyTrack { get }
    @objc optional var playerPosition: Double { get }
    @objc optional var playerState: SpotifyPlayerState { get }
    @objc optional var soundVolume: Int { get }
    
    @objc optional func playpause()
    @objc optional func nextTrack()
    @objc optional func previousTrack()
    
    @objc optional func setPlayerPosition(_ position: Double)
    @objc optional func setSoundVolume(_ volume: Int)
}

// Protocol for Spotify track object
@objc protocol SpotifyTrack: class {
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
    private let application: SpotifyApplication = SBApplication.init(bundleIdentifier: bundleIdentifier)!
    
    // MARK: Song data
    
    var song: Song {
        guard let currentTrack = application.currentTrack else { return Song() }
        
        return Song(name: currentTrack.name!,
                    artist: currentTrack.artist!,
                    album: currentTrack.album!,
                    isPlaying: (application.playerState == SpotifyPlayerStatePlaying),
                    playbackPosition: currentPlaybackPosition()!,
                    duration: trackDuration()!)
    }
    
    // MARK: Playback controls
    
    func togglePlayPause() {
        application.playpause!()
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
    
    func currentPlaybackPosition() -> Double? {
        return application.playerPosition
    }
    
    // TODO: Create a var for trackDuration playbackPosition
    
    func trackDuration() -> Double? {
        guard let currentTrack = application.currentTrack else { return 0 }
        
        return Double(currentTrack.duration!) / 1000
    }
    
    func scrub(to doubleValue: Double? = nil, touching: Bool = false) {
        if !touching, let value = doubleValue {
            application.setPlayerPosition!(value * trackDuration()!)
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
    
    // MARK: Artwork
    
    func artwork() -> Any? {
        return application.currentTrack?.artworkUrl
    }
    
    // MARK: Callbacks
    
    var trackChangedHandler: () -> () = { }
    
    var timeChangedHandler: (Bool, Double?) -> () = { _, _ in }
    
    // MARK: Application identifier
    
    static var bundleIdentifier: String {
        return "com.spotify.client"
    }
    
    // MARK: Notification ID
    
    var notificationID: String {
        return "com.spotify.client.PlaybackStateChanged"
    }
    
}
