//
//  VoxHelper.swift
//  Muse
//
//  Created by Marco Albera on 29/12/16.
//  Copyright © 2016 Edge Apps. All rights reserved.
//

import ScriptingBridge

@objc fileprivate protocol VoxApplication {
    // Track properties
    @objc optional var track:        String { get }
    @objc optional var artist:       String { get }
    @objc optional var album:        String { get }
    @objc optional var totalTime:    Double { get }
    @objc optional var artworkImage: NSImage { get }
    
    // Playback properties
    @objc optional var currentTime:  Double { get }
    @objc optional var playerState:  VoxEPlS { get }
    @objc optional var playerVolume: Double { get }
    @objc optional var repeatState:  VoxERpt { get }
    
    // Playback control functions
    @objc optional func play()
    @objc optional func pause()
    @objc optional func playpause()
    @objc optional func previous()
    @objc optional func next()
    @objc optional func shuffle()
    
    // Playback properties - setters
    @objc optional func setCurrentTime (_ time: Double)
    @objc optional func setPlayerState (_ state: VoxEPlS)
    @objc optional func setPlayerVolume(_ volume: Double)
    @objc optional func setRepeatState (_ state: VoxERpt)
}

// Protocols will implemented and populated through here
extension SBApplication: VoxApplication { }

class VoxHelper: PlayerHelper {
    
    // Singleton contructor
    static let shared = VoxHelper()
    
    // The SBApplication object buond to the helper class
    private let application: VoxApplication? = SBApplication.init(bundleIdentifier: BundleIdentifier)
    
    // MARK: Player features
    
    let doesSendPlayPauseNotification = false
    
    let supportsLiking = false
    
    // MARK: Song data
    
    var song: Song {
        guard let application = application else { return Song() }
        
        return Song(name: application.track!,
                    artist: application.artist!,
                    album: application.album!,
                    duration: application.totalTime!)
    }
    
    // MARK: Playback controls
    
    func play() {
        guard let application = application else { return }
        
        application.play!()
    }
    
    func pause() {
        guard let application = application else { return }
        
        application.pause!()
    }
    
    func togglePlayPause() {
        guard let application = application else { return }
        
        application.playpause!()
        
        execPlayPauseHandler()
    }
    
    func nextTrack() {
        guard let application = application else { return }
        
        application.next!()
        
        trackChangedHandler(true)
    }
    
    func previousTrack() {
        guard let application = application else { return }
        
        application.previous!()
        
        trackChangedHandler(false)
    }
    
    // MARK: Playback status
    
    var playerState: PlayerState {
        guard let application = application else { return .stopped}
        
        // Return current playback status ( R/O )
        if application.playerState == .playing {
            return .playing
        } else if application.playerState == .paused {
            return .paused
        } else if application.playerState == .stopped {
            return .stopped
        }
        
        // By default return stopped status
        return .stopped
    }
    
    var playbackPosition: Double {
        set {
            guard let application = application else { return }
            
            // Set the position on the player
            application.setCurrentTime!(newValue)
        }
        
        get {
            guard let application = application else { return 0 }
            
            guard let playbackPosition = application.currentTime else { return 0 }
            
            // Return current playback position
            return playbackPosition
        }
    }
    
    var trackDuration: Double {
        guard let application = application else { return 0 }
        
        guard let trackDuration = application.totalTime else { return 0 }
        
        // Return current track duration
        return trackDuration
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
            application.setPlayerVolume!(Double(newValue))
        }
        
        get {
            guard let application = application else { return 0 }
            
            guard let volume = application.playerVolume else { return 0 }
            
            // Get current volume
            // casting to Integer because Vox provides a Double
            return Int(volume)
        }
    }
    
    var repeating: Bool {
        set {
            guard let application = application else { return }
            
            let repeating: VoxERpt = newValue ? .repeatAll : .none
            
            // Toggle repeating on the player
            application.setRepeatState!(repeating)
            
            // Call the handler with new repeat value
            execShuffleRepeatChangedHandler(repeatChanged: true)
        }
        
        get {
            guard let application = application else { return false }
            
            guard let repeating = application.repeatState else { return false }
            
            // Return current repeating status
            // 1: repeat one, 2: repeat all 
            return repeating == .repeatOne || repeating == .repeatAll
        }
    }
    
    var shuffling: Bool {
        set {
            guard let application = application else { return }
            
            // Toggle shuffling on the player
            application.shuffle!()
            
            // Call the handler with new shuffle value
            execShuffleRepeatChangedHandler(shuffleChanged: true)
        }
        
        get {
            // Vox does not provide information on shuffling
            // only a toggle function
            return false
        }
    }
    
    // MARK: Artwork
    
    func artwork() -> Any? {
        guard let application = application else { return nil }
        
        return application.artworkImage
    }
    
    // MARK: Callbacks
    
    var playPauseHandler: () -> () = { }
    
    var trackChangedHandler: (Bool) -> () = { _ in }
    
    var timeChangedHandler: (Bool, Double?) -> () = { _, _ in }
    
    var shuffleRepeatChangedHandler: (Bool, Bool) -> () = { _, _ in }
    
    var likeChangedHandler: (Bool) -> () = { _ in }
    
    // MARK: Application identifier
    
    static let BundleIdentifier = "com.coppertino.Vox"
    
    // MARK: Notification ID
    
    static let rawTrackChangedNotification = BundleIdentifier + ".trackChanged"
    
}
