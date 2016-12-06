//
//  PlayerHelper.swift
//  Muse
//
//  Created by Marco Albera on 29/11/16.
//  Copyright © 2016 Edge Apps. All rights reserved.
//

import Foundation

class PlayerHelper {
    
    // Notification ID
    let notificationID: String
    
    // Constants for not. dispatches
    let kPlayerStatePlaying: [String]
    
    // Queries for AppleScript actions
    let qTogglePlayPause, qNextTrack, qPreviousTrack, qPlayerState, qPlaybackPosition: String
    let qSetPlaybackPosition: [String]
    
    // Queries for AppleScript current track data
    let qSongName, qSongAlbum, qSongArtist, qSongDuration: String
    
    // Acces the AppleScript bridge
    let appleScriptBridge = AppleScriptBridge.shared
    
    init(notificationID: String, kPlayerStatePlaying: [String], qTogglePlayPause: String, qNextTrack: String, qPreviousTrack: String, qPlayerState: String, qPlaybackPosition: String, qSetPlaybackPosition: [String], qSongName: String, qSongAlbum: String, qSongArtist: String, qSongDuration: String) {
        self.notificationID = notificationID
        self.kPlayerStatePlaying = kPlayerStatePlaying
        self.qTogglePlayPause = qTogglePlayPause
        self.qNextTrack = qNextTrack
        self.qPreviousTrack = qPreviousTrack
        self.qPlayerState = qPlayerState
        self.qPlaybackPosition = qPlaybackPosition
        self.qSetPlaybackPosition = qSetPlaybackPosition
        self.qSongName = qSongName
        self.qSongAlbum = qSongAlbum
        self.qSongArtist = qSongArtist
        self.qSongDuration = qSongDuration
    }
    
    func togglePlayPause() {
        appleScriptBridge.execAppleScript(qTogglePlayPause)
    }
    
    func nextTrack() {
        appleScriptBridge.execAppleScript(qNextTrack)
    }
    
    func previousTrack() {
        appleScriptBridge.execAppleScript(qPreviousTrack)
    }
    
    func currentPlaybackPosition() -> Float? {
        guard let stringValue = appleScriptBridge.execAppleScriptWithOutput(qPlaybackPosition) else { return nil }
        
        return Float(stringValue)
    }
    
    func goTo(time: Float) {
        appleScriptBridge.setAppleScriptVariable(qSetPlaybackPosition, String(time))
    }
    
    func songFromAppleScriptQuery() -> Song {
        guard
            let playbackPosition = appleScriptBridge.execAppleScriptWithOutput(qPlaybackPosition),
            let duration = appleScriptBridge.execAppleScriptWithOutput(qSongDuration)
        else { return Song() }
        
        
        guard
            let songName = appleScriptBridge.execAppleScriptWithOutput(qSongName),
            let songArtist = appleScriptBridge.execAppleScriptWithOutput(qSongArtist),
            let songAlbum = appleScriptBridge.execAppleScriptWithOutput(qSongAlbum),
            
            let isPlaying = appleScriptBridge.execAppleScriptWithOutput(qPlayerState),
            let songPlaybackPosition = Float(playbackPosition),
            let songDuration = Float(duration)
        else { return Song() }
        
        // Return the object
        return Song(
            name: songName,
            artist: songArtist,
            album: songAlbum,
            isPlaying: kPlayerStatePlaying.contains(isPlaying),
            playbackPosition: songPlaybackPosition,
            duration: songDuration / 1000
        )
    }
    
}
