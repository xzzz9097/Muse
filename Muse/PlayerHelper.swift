//
//  PlayerHelper.swift
//  Muse
//
//  Created by Marco Albera on 29/11/16.
//  Copyright © 2016 Edge Apps. All rights reserved.
//

// Generic protocol for a player application
// AppleScript object
@objc protocol PlayerApplication {
    var isRunning: Bool { get }
}

protocol PlayerHelper {
    
    // MARK: Application
    
    // A type that conforms to PlayerApplication
    associatedtype Application: PlayerApplication
    
    // TODO: Make this private somehow
    var application: Application { get }
    
    // MARK: Player features
    
    var doesSendPlayPauseNotification: Bool { get }
    
    // MARK: Song data
    
    var song: Song { get }
    
    // MARK: Playback controls
    
    func togglePlayPause()
    
    func nextTrack()
    
    func previousTrack()
    
    // MARK: Playback status
    
    var isPlaying: Bool { get }
    
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
        // ( implemented by SBApplication )
        return application.isRunning
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
