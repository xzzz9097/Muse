//
//  PlayerHelper.swift
//  Muse
//
//  Created by Marco Albera on 29/11/16.
//  Copyright © 2016 Edge Apps. All rights reserved.
//

enum PlayerState {
    // Enum for the three possible player states
    case stopped, paused, playing
}

protocol PlayerHelper {
    
    // MARK: Player features
    
    var doesSendPlayPauseNotification: Bool { get }
    
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
    
    var trackChangedHandler: () -> () { set get }
    
    var timeChangedHandler: (Bool, Double?) -> () { set get }
    
    var shuffleRepeatChangedHandler: () -> () { set get }
    
    // MARK: Application identifier
    
    static var BundleIdentifier: String { get }
    
    // MARK: Notification ID
    
    static var TrackChangedNotification: String { get }
    
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
        DispatchQueue.main.run({ self.playPauseHandler() }, after: delayTime)
    }
    
    func execShuffleRepeatChangedHandler() {
        DispatchQueue.main.run({ self.shuffleRepeatChangedHandler() }, after: delayTime)
    }
    
}
