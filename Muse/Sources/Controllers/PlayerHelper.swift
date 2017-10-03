//
//  PlayerHelper.swift
//  Muse
//
//  Created by Marco Albera on 29/11/16.
//  Copyright © 2016 Edge Apps. All rights reserved.
//

// Defines a set of infos to inform the VC
// about player events from the outside
enum PlayerAction: Int {
    case play
    case pause
    case previous
    case next
    case shuffling
    case repeating
    case scrubbing
    case like
    
    @available(OSX 10.12.2, *)
    var image: NSImage? {
        switch self {
        case .play:
            return .play
        case .pause:
            return .pause
        case .previous:
            return .previous
        case .next:
            return .next
        case .shuffling:
            return .shuffling
        case .repeating:
            return .repeating
        case .like:
            return .like
        default:
            return nil
        }
    }
    
    @available(OSX 10.12.2, *)
    var smallImage: NSImage? {
        switch self {
        case .play:
            return image?.resized(to: NSMakeSize(8, 8))
        case .pause:
            return image?.resized(to: NSMakeSize(7, 7))
        case .previous:
            return image?.resized(to: NSMakeSize(12, 12))
        case .next:
            return image?.resized(to: NSMakeSize(12, 12))
        case .shuffling, .repeating:
            return image?.resized(to: NSMakeSize(20, 20))
        case .like:
            return image?.resized(to: NSMakeSize(15, 15))
        default:
            return image
        }
    }
}

// Enum for the three possible player states
enum PlayerState {
    case stopped, paused, playing
}

struct PlayerHelperNotification {
    
    static private let name = Notification.Name("museHelperNotification")
    
    static private let helperNotificationKey = "helperNotification"
    
    // Supported player helper events
    enum Event {
        case play
        case pause
        case nextTrack
        case previousTrack
        case scrub(Bool, Double)
        case shuffling(Bool)
        case repeating(Bool)
        case like(Bool)
    }
    
    // The event associated with the notification
    let event: Event
    
    init(_ event: Event) {
        self.event = event
    }
    
    /**
     Posts the notification of the specified event
     */
    func post() {
        NotificationCenter.default.post(
            name: PlayerHelperNotification.name,
            object: nil,
            userInfo: [PlayerHelperNotification.helperNotificationKey: self])
    }
    
    /**
     Sets up an observer for the specified event
     executing the given closure
     */
    static func observe(block: @escaping (Event) -> ()) {
        NotificationCenter.default.addObserver(
            forName: name,
            object: nil,
            queue: nil)
        { notification in
            if let helperNotification = notification.userInfo?[helperNotificationKey] as? PlayerHelperNotification {
                block(helperNotification.event)
            }
        }
    }
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
        PlayerHelperNotification(isPlaying ? .play : .pause).post()
    }
    
    func nextTrack() {
        self.internalNextTrack()
        
        PlayerHelperNotification(.nextTrack).post()
    }
    
    func previousTrack() {
        self.internalPreviousTrack()
        
        PlayerHelperNotification(.previousTrack).post()
    }
    
    // MARK: Playback status
    
    func scrub(to doubleValue: Double? = nil, touching: Bool) {
        // Override this in extension to provide default args
        self.internalScrub(to: doubleValue, touching: touching)
        
        // TODO: this may also require delayed execution
        PlayerHelperNotification(.scrub(touching, (doubleValue ?? 0) * trackDuration)).post()
    }
    
    // MARK: Playback options
    
    var repeating: Bool {
        set {
            internalRepeating = newValue
            
            PlayerHelperNotification(.repeating(newValue)).post()
        }

        get {
            return internalRepeating
        }
    }
    
    var shuffling: Bool {
        set {
            internalShuffling = newValue
            
            PlayerHelperNotification(.shuffling(newValue)).post()
        }
        
        get {
            return internalShuffling
        }
    }
}

extension PlayerHelper {
    
    var liked: Bool {
        set { }
        get { return false }
    }
}

extension PlayerHelper where Self: LikableInternalPlayerHelper {
    
    // MARK: Starring
    
    var liked: Bool {
        set {
            internalSetLiked(newValue) { liked in
                PlayerHelperNotification(.like(liked)).post()
            }
        }
        
        get {
            return internalLiked
        }
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
        return NSWorkspace.shared()
            .absolutePathForApplication(withBundleIdentifier: Self.BundleIdentifier)
    }
    
    var icon: NSImage? {
        guard let path = path else { return nil }
        
        // Returns the icon of the player application
        return NSWorkspace.shared().icon(forFile: path)
    }
    
    // MARK: Notification ID
    
    var TrackChangedNotification: NSNotification.Name {
        // Returns the NSNotification.Name for an observer
        return NSNotification.Name(rawValue: Self.rawTrackChangedNotification)
    }
    
}
