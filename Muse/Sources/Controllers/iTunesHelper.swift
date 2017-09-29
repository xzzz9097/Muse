//
//  iTunesHelper.swift
//  Muse
//
//  Created by Marco Albera on 28/01/17.
//  Copyright © 2017 Edge Apps. All rights reserved.
//

import ScriptingBridge

// Protocol for iTunes application queries
@objc fileprivate protocol iTunesApplication {
    // Track properties
    @objc optional var currentTrack: iTunesTrackProtocol { get }
    
    // Playback properties
    @objc optional var playerPosition: Double { get }
    @objc optional var playerState:    iTunesEPlS { get }
    @objc optional var soundVolume:    Int { get }
    @objc optional var songRepeat:     iTunesERpt { get }
    @objc optional var shuffleEnabled: Bool { get }
    
    // Playback control functions
    @objc optional func playOnce(_ once: Bool)
    @objc optional func pause()
    @objc optional func playpause()
    @objc optional func nextTrack()
    @objc optional func previousTrack()
    
    // Playback properties - setters
    @objc optional func setPlayerPosition(_ position: Double)
    @objc optional func setSoundVolume   (_ volume: Int)
    @objc optional func setSongRepeat    (_ songRepeat: iTunesERpt)
    @objc optional func setShuffleEnabled(_ shuffleEnabled: Bool)
}

// Protocol for iTunes track object
@objc fileprivate protocol iTunesTrackProtocol {
    // Track properties
    @objc optional var name:     String { get }
    @objc optional var artist:   String { get }
    @objc optional var album:    String { get }
    @objc optional var duration: Double { get }
    @objc optional var artworks: [iTunesArtworkProtocol] { get }
    @objc optional var loved:    Bool { get }
    
    // Track properties - setters
    @objc optional func setLoved(_ loved: Bool)
}

// Protocol for iTunes artwork object
// Every track provides an array of artworks
@objc fileprivate protocol iTunesArtworkProtocol {
    @objc optional var data:        NSImage { get }
    @objc optional var description: String { get }
}

extension SBObject: iTunesArtworkProtocol { }

// Protocols will be implemented and populated through here
extension SBApplication: iTunesApplication { }

class iTunesHelper: PlayerHelper {
    
    // SIngleton constructor
    static let shared = iTunesHelper()
    
    // The SBApplication object bound to the helper class
    private let application: iTunesApplication? = SBApplication.init(bundleIdentifier: BundleIdentifier)
    
    // MARK: Player features
    
    let doesSendPlayPauseNotification = true
    
    let supportsLiking = true
    
    // MARK: Song data
    
    var song: Song {
        guard let currentTrack = application?.currentTrack else { return Song() }
        
        return Song(name: currentTrack.name!,
                    artist: currentTrack.artist!,
                    album: currentTrack.album!,
                    duration: trackDuration)
    }
    
    // MARK: Playback controls
    
    func internalPlay() {
        application?.playOnce?(false)
    }
    
    func internalPause() {
        application?.pause?()
    }
    
    func internalTogglePlayPause() {
        application?.playpause?()
    }
    
    func internalNextTrack() {
        application?.nextTrack?()
        
        trackChangedHandler(true)
    }
    
    func internalPreviousTrack() {
        application?.previousTrack?()
        
        trackChangedHandler(false)
    }
    
    // MARK: Playback status
    
    var playerState: PlayerState {
        // Return current playback status ( R/O )
        switch application?.playerState {
        case iTunesEPlSPlaying?:
            return .playing
        case iTunesEPlSPaused?:
            return .paused
        case iTunesEPlSStopped?:
            return .stopped
        default:
            // By default return stopped status
            return .stopped
        }
    }
    
    var playbackPosition: Double {
        set {
            // Set the position on the player
            application?.setPlayerPosition?(newValue)
        }
        
        get {
            // Return current playback position
            return application?.playerPosition ?? 0
        }
    }
    
    var trackDuration: Double {
        // Return current track duration
        return application?.currentTrack?.duration ?? 0
    }
    
    func internalScrub(to doubleValue: Double?, touching: Bool) {
        if !touching, let value = doubleValue {
            playbackPosition = value * trackDuration
        }
        
        timeChangedHandler(touching, doubleValue)
    }
    
    // MARK: Playback options
    
    var volume: Int {
        set {
            // Set the volume on the player
            application?.setSoundVolume?(newValue)
        }
        
        get {
            // Get current volume
            return application?.soundVolume ?? 0
        }
    }
    
    var repeating: Bool {
        set {
            let repeating: iTunesERpt = newValue ? iTunesERptAll : iTunesERptOff
            
            // Toggle repeating on the player
            application?.setSongRepeat!(repeating)
            
            // Call the handler with new repeat value
            execShuffleRepeatChangedHandler(repeatChanged: true)
        }
        
        get {
            guard let repeating = application?.songRepeat else { return false }
            
            // Return current repeating status
            return repeating == iTunesERptOne || repeating == iTunesERptAll
        }
    }
    
    var shuffling: Bool {
        set {
            // Toggle shuffling on the player
            application?.setShuffleEnabled?(newValue)
            
            // Call the handler with new shuffle value
            execShuffleRepeatChangedHandler(shuffleChanged: true)
        }
        
        get {
            // Return current shuffling status
            return application?.shuffleEnabled ?? false
        }
    }
    
    // MARK: Artwork
    
    func artwork() -> Any? {
        // Returns the first available artwork
        return application?.currentTrack?.artworks?[0].data
    }
    
    // MARK: Starring
    
    var liked: Bool {
        set {
            // Stars the current track
            application?.currentTrack?.setLoved?(newValue)
            
            // Call the handler with new like value
            likeChangedHandler(newValue)
        }
        
        get {
            // Returns true if the current track is starred
            return application?.currentTrack?.loved ?? false
        }
    }
    
    // MARK: Callbacks
        
    var trackChangedHandler: (Bool) -> () = { _ in }
    
    var timeChangedHandler: (Bool, Double?) -> () = { _, _ in }
    
    var shuffleRepeatChangedHandler: (Bool, Bool) -> () = { _, _ in }
    
    var likeChangedHandler: (Bool) -> () = { _ in }
    
    // MARK: Application identifier
    
    static let BundleIdentifier = "com.apple.iTunes"
    
    // MARK: Notification ID
    
    static let rawTrackChangedNotification = BundleIdentifier + ".playerInfo"
    
}
