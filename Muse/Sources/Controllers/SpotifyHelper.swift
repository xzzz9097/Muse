//
//  SpotifyHelper.swift
//  Muse
//
//  Created by Marco Albera on 21/11/16.
//  Copyright © 2016 Edge Apps. All rights reserved.
//

import ScriptingBridge

import SpotifyKit

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
    @objc optional func play()
    @objc optional func playTrack(_ uri: String, inContext: String)
    @objc optional func pause()
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
    @objc optional var id:         String { get }
    @objc optional var name:       String { get }
    @objc optional var artist:     String { get }
    @objc optional var album:      String { get }
    @objc optional var duration:   Int { get }
    @objc optional var artworkUrl: String { get }
}

// The SpotifyKit object, available to all classes
var spotifyManager = SpotifyManager(
    with: SpotifyManager.SpotifyDeveloperApplication(
        clientId: "fff95f1ce70e4dffb534bf9bbdf8da6d",
        clientSecret: "d5757f19f36644d4b85b9f63abe0ef1f",
        redirectUri: "muse://callback"
    )
)

// Protocols will implemented and populated through here
extension SBApplication: SpotifyApplication { }

class SpotifyHelper: PlayerHelper, LikablePlayerHelper, InternalPlayerHelper, LikableInternalPlayerHelper, SearchablePlayerHelper, PlayablePlayerHelper, PlaylistablePlayerHelper {
    
    // Singleton constructor
    static let shared = SpotifyHelper()
    
    // The SBApplication object buond to the helper class
    private let application: SpotifyApplication? = SBApplication.init(bundleIdentifier: BundleIdentifier)
    
    private init() {
        if !spotifyManager.hasToken {
            // Try to authenticate if there's no token
            spotifyManager.authorize()
        } else {
            // Refresh the token if present
            spotifyManager.refreshToken { _ in }
        }
    }
    
    // MARK: Player features
    
    let doesSendPlayPauseNotification = true
    
    // MARK: Swiftify methods
    
    /**
     Authorize Swiftify with Spotify Web API
     */
    func authorize() {
        spotifyManager.authorize()
    }
    
    /**
     Save token after authorization code has been received
     */
    func saveToken(from authorizationCode: String) {
        spotifyManager.saveToken(from: authorizationCode)
    }
    
    /**
     Checks if a token is saved and reports thrugh a handler
     */
    func isSaved(completionHandler: @escaping (Bool) -> Void) {
        spotifyManager.isSaved(trackId: id) { saved in
            self._liked = saved
            
            completionHandler(saved)
        }
    }
    
    // MARK: Song data
    
    var song: Song {
        guard let currentTrack = application?.currentTrack else { return Song() }
        
        return Song(address: currentTrack.id!,
                    name: currentTrack.name!,
                    artist: currentTrack.artist!,
                    album: currentTrack.album!,
                    duration: trackDuration)
    }
    
    /**
     Returns Spotify ID of the currently playing track.
     Used for saving in user's library.
     */
    private var id: String {
        guard   let application  = application,
                let currentTrack = application.currentTrack,
                let id           = currentTrack.id,
                id.count > 14 else { return "" }
        
        // AppleScript returns "spotify:track:id"
        // We need to cut the initial part of the string
        return id.substring(from: id.index(id.startIndex, offsetBy: 14))
    }
    
    // MARK: Playback controls
    
    func internalPlay() {
        application?.play?()
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
    
    func play(uri: String, context: String = "") {
        application?.playTrack?(uri, inContext: context)
    }
    
    // MARK: Playback status
    
    var playerState: PlayerState {
        // Return current playback status ( R/O )
        switch application?.playerState {
        case SpotifyEPlSPlaying?:
            return .playing
        case SpotifyEPlSPaused?:
            return .paused
        case SpotifyEPlSStopped?:
            return .stopped
        default:
            // By default return stopped status
            return .stopped
        }
    }
    
    var playbackPosition: Double {
        set {
            // Set the position on the player
            application?.setPlayerPosition!(newValue)
        }
        
        get {
            // Return current playback position
            return application?.playerPosition ?? 0
        }
    }
    
    var trackDuration: Double {
        // Return current track duration
        // It needs a cast because 'duration' from ScriptingBridge is Int
        return Double(application?.currentTrack?.duration ?? 0) / 1000
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
            // Toggle repeating on the player
            application?.setRepeating?(newValue)
        }
        
        get {
            // Return current repeating status
            return application?.repeating ?? false
        }
    }
    
    var internalShuffling: Bool {
        set {
            // Toggle shuffling on the player
            application?.setShuffling?(newValue)
        }
        
        get {
            // Return current shuffling status
            return application?.shuffling ?? false
        }
    }
    
    // MARK: Artwork
    
    func artwork() -> Any? {
        return application?.currentTrack?.artworkUrl
    }
    
    // MARK: Starring
    
    // The instance variable for like status
    private var _liked: Bool?
    
    func internalSetLiked(_ liked: Bool, completionHandler: @escaping (Bool) -> ()) {
        switch liked {
        case true:
            spotifyManager.save(trackId: id) { [weak self] saved in
                if saved {
                    // Update the ivar
                    self?._liked = true
                    // Run the handler
                    completionHandler(true)
                }
            }
        case false:
            spotifyManager.delete(trackId: id) { [weak self] deleted in
                if deleted {
                    // Update the ivar
                    self?._liked = false
                    // Run the handler
                    completionHandler(false)
                }
            }
        }
    }
    
    var internalLiked: Bool { return _liked ?? false }
    
    func fetchTrackInfo(title: String,
                        artist: String,
                        completionHandler: @escaping (SpotifyTrack) -> Void) {
        spotifyManager.getTrack(title: title,
                                artist: artist,
                                completionHandler: completionHandler)
    }
    
    // MARK: Searching
    
    func search(title: String, completionHandler: @escaping (([Song]) -> Void)) {
        // Map our parsed SpotifyTracks to standard song items
        spotifyManager.find(SpotifyTrack.self, title) {
            completionHandler($0.map { $0.song })
        }
    }
    
    // MARK: Playing
    
    func play(_ address: String) {
        // Pass the helper play call to Spotify ScriptingBridge binding
        play(uri: address)
    }
    
    // MARK: Playlists
    
    func playlists(completionHandler: @escaping (([Playlist]) -> Void)) {
        spotifyManager.library(SpotifyPlaylist.self) {
            completionHandler($0.map { $0.playlist })
        }
    }
    
    /**
     - parameter playlist: the Spotify URI of the playlist
     */
    func play(playlist: String) {
        play(uri: playlist)
    }
    
    // MARK: Application identifier
    
    static let BundleIdentifier = "com.spotify.client"
    
    // MARK: Notification ID
    
    static let rawTrackChangedNotification = BundleIdentifier + ".PlaybackStateChanged"
    
    // MARK: Account
    
    static func account(completionHandler: @escaping ((Account) -> Void)) {
        spotifyManager.myProfile { profile in
            guard let imageURL = URL(string: profile.artUri) else { return }
            
            NSImage.download(from: imageURL, fallback: NSImage(named: NSImage.Name.userAccounts)!) {
                completionHandler(Account(username: profile.name,
                                          email: profile.email ?? "",
                                          image: $0.oval()))
            }
        }
    }
    
}

extension SpotifyTrack {
    
    // Convert SpotifyTrack to a Muse Player song item
    var song: Song {
        return Song(address: self.uri,
                    name: self.name,
                    artist: self.artist.name,
                    album: self.album?.name ?? "",
                    duration: 0) // TODO: add proper duration!
    }
}

extension SpotifyPlaylist {
    
    // Convert SpotifyPlaylist to a Muse Player playlist item
    var playlist: Playlist {
        return Playlist(id: self.uri,
                        name: self.name,
                        count: self.count)
    }
}
