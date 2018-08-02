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
    @objc optional func openLocation(_ url: NSURL)
    
    // Playback properties - setters
    @objc optional func setPlayerPosition(_ position: Double)
    @objc optional func setSoundVolume   (_ volume: Int)
    @objc optional func setSongRepeat    (_ songRepeat: iTunesERpt)
    @objc optional func setShuffleEnabled(_ shuffleEnabled: Bool)
}

// Protocol for iTunes track object
@objc fileprivate protocol iTunesTrackProtocol {
    // Track properties
    @objc optional var persistentID: String { get }
    @objc optional var location:     String { get }
    @objc optional var name:         String { get }
    @objc optional var artist:       String { get }
    @objc optional var album:        String { get }
    @objc optional var duration:     Double { get }
    @objc optional var artworks:     [iTunesArtworkProtocol] { get }
    @objc optional var loved:        Bool { get }
    
    // Track properties - setters
    @objc optional func setLoved(_ loved: Bool)
}

// Protocol for iTunes artwork object
// Every track provides an array of artworks
@objc fileprivate protocol iTunesArtworkProtocol {
    @objc optional var data:        NSImage { get }
    @objc optional var description: String { get }
}

// The iTunes library
fileprivate let library = try? ITLibrary(apiVersion: "1.0")

// All songs in the library
fileprivate var librarySongs: [ITLibMediaItem]? {
    return library?.allMediaItems.filter { $0.mediaKind == .kindSong }
}

extension SBObject: iTunesArtworkProtocol { }

// Protocols will be implemented and populated through here
extension SBApplication: iTunesApplication { }

class iTunesHelper: PlayerHelper, LikablePlayerHelper, InternalPlayerHelper, LikableInternalPlayerHelper, SearchablePlayerHelper, PlayablePlayerHelper, PlaylistablePlayerHelper {
    
    // SIngleton constructor
    static let shared = iTunesHelper()
    
    // The SBApplication object bound to the helper class
    private let application: iTunesApplication? = SBApplication.init(bundleIdentifier: BundleIdentifier)
    
    // MARK: Player features
    
    let doesSendPlayPauseNotification = true
    
    // MARK: Song data
    
    var song: Song {
        guard let currentTrack = application?.currentTrack else { return Song() }
        
        return Song(address: currentTrack.persistentID!,
                    name: currentTrack.name!,
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
    }
    
    func internalPreviousTrack() {
        application?.previousTrack?()
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
    
    var internalRepeating: Bool {
        set {
            let repeating: iTunesERpt = newValue ? iTunesERptAll : iTunesERptOff
            
            // Toggle repeating on the player
            application?.setSongRepeat!(repeating)
        }
        
        get {
            guard let repeating = application?.songRepeat else { return false }
            
            // Return current repeating status
            return repeating == iTunesERptOne || repeating == iTunesERptAll
        }
    }
    
    var internalShuffling: Bool {
        set {
            // Toggle shuffling on the player
            application?.setShuffleEnabled?(newValue)
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
    
    func internalSetLiked(_ liked: Bool, completionHandler: @escaping (Bool) -> ()) {
        // Stars the current track
        application?.currentTrack?.setLoved?(liked)
        
        // Calls the handler
        completionHandler(liked)
    }
    
    var internalLiked: Bool { return application?.currentTrack?.loved ?? false }
    
    // MARK: Searching
    
    func search(title: String, completionHandler: @escaping (([Song]) -> Void)) {
        guard let songs = librarySongs else { return }
        
        // Search for matching tracks and asynchronously dispatch them
        // TODO: also evaluate match for artist and album name
        DispatchQueue.main.async {
            completionHandler(songs
                .filter { $0.title.lowercased().contains(title.lowercased()) }
                .map { $0.song })
        }
    }
    
    // MARK: Playing
    
    func play(_ address: String) {
        // Build an AppleScript query to play our track
        // because ScriptingBridge binding for opening a file seems broken
        let query = "tell application \"iTunes\"\n play POSIX file \"\(address)\" \nend tell"
        
        NSAppleScript(source: query)?.executeAndReturnError(nil)
    }
    
    // MARK: Playlists
    
    func playlists(completionHandler: @escaping (([Playlist]) -> Void)) {
        guard let playlists = library?.allPlaylists else { return }
        
        // Build playlists by mapping the initializer
        // TODO: extend ITLib to create a converter with more properties
        DispatchQueue.main.async {
            completionHandler(
                playlists
                    .filter { !$0.isMaster && $0.distinguishedKind == .kindNone }
                    .map { Playlist(id: Int($0.persistentID),
                                    name: $0.name,
                                    count: $0.items.count) }
            )
        }
    }
    
    func play(playlist named: String) {
        // Build an AppleScript query to play our playlist
        let query = "tell application \"iTunes\"\n play user playlist named \"\(named)\" \nend tell"
        
        NSAppleScript(source: query)?.executeAndReturnError(nil)
    }
    
    // MARK: Application identifier
    
    static let BundleIdentifier = "com.apple.iTunes"
    
    // MARK: Notification ID
    
    static let rawTrackChangedNotification = BundleIdentifier + ".playerInfo"
    
}

extension ITLibMediaItem {
    // TODO: constrain protocl to mediaKindSong items
    
    var song: Song {
        return Song(address: self.location?.path ?? "", // TODO: check for remote tracks
                    name: self.title,
                    artist: self.artist?.name ?? "",
                    album: self.album.title ?? "",
                    duration: Double(self.totalTime))
    }
}
