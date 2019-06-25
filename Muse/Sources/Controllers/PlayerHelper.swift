//
//  PlayerHelper.swift
//  Muse
//
//  Created by Marco Albera on 29/11/16.
//  Copyright © 2016 Edge Apps. All rights reserved.
//

// Enum for the three possible player states
enum PlayerState {
    case stopped, paused, playing
}

// An internal protocol that contains all the playback control functions
// This allows us to keeps these functions obscured from PlayerHelper objects
// but to call them through desired and exposed functions
// see -> extension PlayerHelper where Self: InternalPlayerHelper
protocol InternalPlayerHelper {
    
    func internalPlay()
    
    func internalPause()
    
    func internalTogglePlayPause()
    
    func internalNextTrack()
    
    func internalPreviousTrack()
    
    func internalScrub(to doubleValue: Double?, touching: Bool)
    
    var internalRepeating: Bool { set get }
    
    var internalShuffling: Bool { set get }
}

protocol PlayerHelper {
    
    // MARK: Player features
    
    var doesSendPlayPauseNotification: Bool { get }
    
    // MARK: Song data
    
    var song: Song { get }
    
    // MARK: Playback controls
    
    func play()
    
    func pause()
    
    func togglePlayPause()
    
    func nextTrack()
    
    func previousTrack()
    
    // MARK: Playback status
    
    var playerState: PlayerState { get }
    
    var playbackPosition: Double { set get }
    
    var trackDuration: Double { get }
    
    func scrub(to doubleValue: Double?, touching: Bool)
    
    // MARK: Playback options
    
    var volume: Int { set get }
    
    var repeating: Bool { set get }
    
    var shuffling: Bool { set get }
    
    // MARK: Artwork
    
    func artwork() -> Any?
    
    // MARK: Application identifier
    
    static var BundleIdentifier: String { get }
    
    // MARK: Notification ID
    
    static var rawTrackChangedNotification: String { get }
    
}

protocol LikableInternalPlayerHelper {
    
    func internalSetLiked(_ liked: Bool, completionHandler: @escaping (Bool) -> ())
    
    var internalLiked: Bool { get }
}

protocol LikablePlayerHelper {
    
    // MARK: Starring
    
    var liked: Bool { set get }
    
    @discardableResult
    mutating func toggleLiked() -> Bool
}

protocol SearchablePlayerHelper {
    
    // MARK: Searching
    
    func search(title: String, completionHandler: @escaping (([Song]) -> Void))
}

protocol PlaylistablePlayerHelper {
    
    // MARK: Playlists
    
    func playlists(completionHandler: @escaping (([Playlist]) -> Void))
    
    func play(playlist: String)
}

protocol PlayablePlayerHelper {
    
    func play(_ address: String)
}

extension PlayerHelper where Self: InternalPlayerHelper {
    
    // MARK: Playback controls
    
    func play() {
        self.internalPlay()
    }
    
    func pause() {
        self.internalPause()
    }
    
    func togglePlayPause() {
        self.internalTogglePlayPause()
        
        // TODO: a slight delay may be needed, was used with closure
        PlayerNotification(isPlaying ? .play : .pause).post()
    }
    
    func nextTrack() {
        self.internalNextTrack()
        
        PlayerNotification(.next).post()
    }
    
    func previousTrack() {
        self.internalPreviousTrack()
        
        PlayerNotification(.previous).post()
    }
    
    // MARK: Playback status
    
    func scrub(to doubleValue: Double? = nil, touching: Bool) {
        // Override this in extension to provide default args
        self.internalScrub(to: doubleValue, touching: touching)
        
        // TODO: this may also require delayed execution
        PlayerNotification(.scrub(touching, (doubleValue ?? 0) * trackDuration)).post()
    }
    
    // MARK: Playback options
    
    var repeating: Bool {
        set {
            internalRepeating = newValue
            
            PlayerNotification(.repeating(newValue)).post()
        }

        get {
            return internalRepeating
        }
    }
    
    var shuffling: Bool {
        set {
            internalShuffling = newValue
            
            PlayerNotification(.shuffling(newValue)).post()
        }
        
        get {
            return internalShuffling
        }
    }
}

@discardableResult
fileprivate func toggle(value: inout Bool) -> Bool {
    let newValue = !value
    value = newValue
    
    return newValue
}

extension PlayerHelper {
    
    var liked: Bool {
        set { }
        get { return false }
    }
    
    @discardableResult
    mutating func toggleRepeating() -> Bool {
        return toggle(value: &repeating)
    }
    
    @discardableResult
    mutating func toggleShuffling() -> Bool {
        return toggle(value: &shuffling)
    }
}

extension PlayerHelper where Self: LikableInternalPlayerHelper {
    
    // MARK: Starring
    
    var liked: Bool {
        set {
            internalSetLiked(newValue) { liked in
                PlayerNotification(.like(liked)).post()
            }
        }
        
        get {
            return internalLiked
        }
    }
}

extension PlayerHelper where Self: LikablePlayerHelper {
    
    @discardableResult
    mutating func toggleLiked() -> Bool {
        return toggle(value: &liked)
    }
}

extension PlayerHelper {
    
    // MARK: Player availability
    
    var isAvailable: Bool {
        // Returns if the application is running
        return NSRunningApplication
            .runningApplications(withBundleIdentifier: Self.BundleIdentifier).count > 0
    }
    
    // MARK: Playback status
    
    var isPlaying: Bool {
        // Returns if the player is playing a track
        return playerState == .playing
    }
    
    // MARK: App data
    
    var name: String? {
        // Returns the name of the application
        // return application.name
        return Bundle.init(identifier: Self.BundleIdentifier)?
            .object(forInfoDictionaryKey: kCFBundleNameKey as String) as? String
    }
    
    var path: String? {
        // Returns the path of the player application
        return NSWorkspace.shared
            .absolutePathForApplication(withBundleIdentifier: Self.BundleIdentifier)
    }
    
    var icon: NSImage? {
        guard let path = path else { return nil }
        
        // Returns the icon of the player application
        return NSWorkspace.shared.icon(forFile: path)
    }
    
    // MARK: Notification ID
    
    var TrackChangedNotification: NSNotification.Name {
        // Returns the NSNotification.Name for an observer
        return NSNotification.Name(rawValue: Self.rawTrackChangedNotification)
    }
    
}
