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
let kSpotifySongName = "Name"
let kSpotifySongAlbum = "Album"
let kSpotifySongArtist = "Artist"
let kSpotifyPlayerState = "Player State"
let kSpotifyPlayerStatePlaying = "Playing"
let kSpotifySongPlaybackPosition = "Playback Position"
let kSpotifySongDuration = "Duration"

// Queries for Spotify's AppleScript actions
let qSpotifyTogglePlayPause = "tell application \"Spotify\"\nplaypause\nend tell"
let qSpotifyNextTrack = "tell application \"Spotify\"\nnext track\nend tell"
let qSpotifyPreviousTrack = "tell application \"Spotify\"\nprevious track\nend tell"
let qSpotifyArtworkURL = "tell application \"Spotify\"\nartwork url of current track\nend tell"
let qSpotifyPlaybackPosition = "tell application \"Spotify\"\nplayer position\nend tell"
let qSpotifySetPlaybackPosition = ["tell application \"Spotify\"\nset player position to ","\nend tell"]

class SpotifyHelper: NSObject {
    
    func togglePlayPause() {
        execAppleScript(qSpotifyTogglePlayPause)
    }
    
    func nextTrack() {
        execAppleScript(qSpotifyNextTrack)
    }
    
    func previousTrack() {
        execAppleScript(qSpotifyPreviousTrack)
    }
    
    func currentPlaybackPosition() -> Float? {
        guard let stringValue = execAppleScriptWithOutput(qSpotifyPlaybackPosition) else { return nil }
        
        return Float(stringValue)
    }
    
    func goTo(time: Float) {
        setAppleScriptVariable(qSpotifySetPlaybackPosition, String(time))
    }
    
    func artworkURL() -> String? {
        return execAppleScriptWithOutput(qSpotifyArtworkURL)
    }
    
    func songFromNotification(notification: NSNotification) -> Song {
        // Retrieve new value from notification
        guard let userInfo = notification.userInfo else { return Song() }
        
        guard
            let songName = userInfo[kSpotifySongName] as? String,
            let songArtist = userInfo[kSpotifySongArtist] as? String,
            let songAlbum = userInfo[kSpotifySongAlbum] as? String,
        
            let songArtworkURL = artworkURL(),
        
            let isPlaying = userInfo[kSpotifyPlayerState] as? String,
            let songPlaybackPosition = userInfo[kSpotifySongPlaybackPosition] as? Float,
            let songDuration = userInfo[kSpotifySongDuration] as? Float
        else { return Song() }
        
        // Return the object
        return Song(
            name: songName,
            artist: songArtist,
            album: songAlbum,
            artworkURL: songArtworkURL,
            isPlaying: isPlaying == kSpotifyPlayerStatePlaying,
            playbackPosition: songPlaybackPosition,
            duration: songDuration / 1000
        )
    }
    
    func execAppleScript(_ script: String) {
        var error: NSDictionary?
        
        if let scriptObject = NSAppleScript(source: script) {
            scriptObject.executeAndReturnError(&error)
        }
    }
    
    func setAppleScriptVariable(_ preScript: [String], _ value: String) {
        var error: NSDictionary?
        
        let script = preScript[0] + value + preScript[1]
        
        if let scriptObject = NSAppleScript(source: script) {
            scriptObject.executeAndReturnError(&error)
        }
    }
    
    func execAppleScriptWithOutput(_ script: String) -> String? {
        var error: NSDictionary?
        
        if let scriptObject = NSAppleScript(source: script) {
            let output: NSAppleEventDescriptor = scriptObject.executeAndReturnError(&error)
            
            if (output.stringValue != nil) {
                return output.stringValue
            }
        }
        
        return nil
    }
    
}
