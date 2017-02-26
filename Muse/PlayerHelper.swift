//
//  PlayerHelper.swift
//  Muse
//
//  Created by Marco Albera on 29/11/16.
//  Copyright © 2016 Edge Apps. All rights reserved.
//

// Defines a set of infos to inform the VC
// about player events from the outside
enum PlayerAction {
    case play
    case pause
    case previous
    case next
    case shuffling
    case repeating
    case scrubbing
}

// Enum for the three possible player states
enum PlayerState {
    case stopped, paused, playing
}

protocol PlayerHelper {
    
    // MARK: Player features
    
    var doesSendPlayPauseNotification: Bool { get }
    
    var supportsStarring: Bool { get }
    
    // MARK: Song data
    
    var song: Song { get }
    
    // MARK: Playback controls
    
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
    
    // MARK: Callbacks
    
    var playPauseHandler: () -> () { set get }
    
    var trackChangedHandler: (Bool) -> () { set get }
    
    var timeChangedHandler: (Bool, Double?) -> () { set get }
    
    var shuffleRepeatChangedHandler: (Bool, Bool) -> () { set get }
    
    // MARK: Application identifier
    
    static var BundleIdentifier: String { get }
    
    // MARK: Notification ID
    
    static var rawTrackChangedNotification: String { get }
    
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
    
    func scrub(to doubleValue: Double? = nil, touching: Bool = false) {
        // Override this in extension to provide default args
        self.scrub(to: doubleValue, touching: touching)
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
        return NSWorkspace.shared()
            .absolutePathForApplication(withBundleIdentifier: Self.BundleIdentifier)
    }
    
    var icon: NSImage? {
        guard let path = path else { return nil }
        
        // Returns the icon of the player application
        return NSWorkspace.shared().icon(forFile: path)
    }
    
    // MARK: Callback executors
    
    // The time (in millis) after which
    // the instructions will run
    var delayTime: Int { return 5 }
    
    func execPlayPauseHandler() {
        DispatchQueue.main.run(after: delayTime) { self.playPauseHandler() }
    }
    
    func execShuffleRepeatChangedHandler(shuffleChanged: Bool = false, repeatChanged: Bool = false) {
        DispatchQueue.main.run(after: delayTime) { self.shuffleRepeatChangedHandler(shuffleChanged, repeatChanged) }
    }
    
    // MARK: Notification ID
    
    var TrackChangedNotification: NSNotification.Name {
        // Returns the NSNotification.Name for an observer
        return NSNotification.Name(rawValue: Self.rawTrackChangedNotification)
    }
    
}
