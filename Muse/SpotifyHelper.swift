//
//  SpotifyHelper.swift
//  Muse
//
//  Created by Marco Albera on 21/11/16.
//  Copyright © 2016 Edge Apps. All rights reserved.
//

import Cocoa

// Spotify notification ID
let spotifyNotificationID = "com.spotify.client.PlaybackStateChanged"

// Constants for Spotify not. dispatches
let kSpotifyPlayerStatePlaying = ["Playing", "kPSP"]

// Queries for Spotify's AppleScript actions
let qSpotifyTogglePlayPause = "tell application \"Spotify\"\nplaypause\nend tell"
let qSpotifyNextTrack = "tell application \"Spotify\"\nnext track\nend tell"
let qSpotifyPreviousTrack = "tell application \"Spotify\"\nprevious track\nend tell"
let qSpotifyPlayerState = "tell application \"Spotify\"\nplayer state\nend tell"
let qSpotifyPlaybackPosition = "tell application \"Spotify\"\nplayer position\nend tell"
let qSpotifySetPlaybackPosition = ["tell application \"Spotify\"\nset player position to ","\nend tell"]

// Queris for Spotify's AppleScript current track data
let qSpotifySongName = "tell application \"Spotify\"\nname of current track\nend tell"
let qSpotifySongAlbum = "tell application \"Spotify\"\nartist of current track\nend tell"
let qSpotifySongArtist = "tell application \"Spotify\"\nalbum of current track\nend tell"
let qSpotifySongDuration = "tell application \"Spotify\"\nduration of current track\nend tell"
let qSpotifyArtworkURL = "tell application \"Spotify\"\nartwork url of current track\nend tell"

class SpotifyHelper {
    
    // Singleton constructor
    static let sharedInstance = SpotifyHelper()
    
    // Make standard init private
    private init() {}
    
    // Acces the AppleScript bridge
    let appleScriptBridge = AppleScriptBridge.shared
    
    func togglePlayPause() {
        appleScriptBridge.execAppleScript(qSpotifyTogglePlayPause)
    }
    
    func nextTrack() {
        appleScriptBridge.execAppleScript(qSpotifyNextTrack)
    }
    
    func previousTrack() {
        appleScriptBridge.execAppleScript(qSpotifyPreviousTrack)
    }
    
    func currentPlaybackPosition() -> Float? {
        guard let stringValue = appleScriptBridge.execAppleScriptWithOutput(qSpotifyPlaybackPosition) else { return nil }
        
        return Float(stringValue)
    }
    
    func goTo(time: Float) {
        appleScriptBridge.setAppleScriptVariable(qSpotifySetPlaybackPosition, String(time))
    }
    
    func artworkURL() -> String? {
        return appleScriptBridge.execAppleScriptWithOutput(qSpotifyArtworkURL)
    }
    
    func songFromAppleScriptQuery() -> Song {
        guard
            let playbackPosition = appleScriptBridge.execAppleScriptWithOutput(qSpotifyPlaybackPosition),
            let duration = appleScriptBridge.execAppleScriptWithOutput(qSpotifySongDuration)
        else { return Song() }
        
        
        guard
            let songName = appleScriptBridge.execAppleScriptWithOutput(qSpotifySongName),
            let songArtist = appleScriptBridge.execAppleScriptWithOutput(qSpotifySongArtist),
            let songAlbum = appleScriptBridge.execAppleScriptWithOutput(qSpotifySongAlbum),
        
            let songArtworkURL = artworkURL(),
        
            let isPlaying = appleScriptBridge.execAppleScriptWithOutput(qSpotifyPlayerState),
            let songPlaybackPosition = Float(playbackPosition),
            let songDuration = Float(duration)
        else { return Song() }
                
        // Return the object
        return Song(
            name: songName,
            artist: songArtist,
            album: songAlbum,
            artworkURL: songArtworkURL,
            isPlaying: kSpotifyPlayerStatePlaying.contains(isPlaying),
            playbackPosition: songPlaybackPosition,
            duration: songDuration / 1000
        )
    }
    
}
