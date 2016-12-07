//
//  PlayerHelper.swift
//  Muse
//
//  Created by Marco Albera on 29/11/16.
//  Copyright © 2016 Edge Apps. All rights reserved.
//

import Foundation

class PlayerHelper {
    
    enum PHQuery {
        // Queries for AppleScript actions
        case togglePlayPause
        case nextTrack
        case previousTrack
        case playerState
        case playbackPosition
        
        // Playback position set query
        case setPlaybackPosition
        
        // Queries for AppleScript current track data
        case songName
        case songAlbum
        case songArtist
        case songDuration
    }
    
    private var queries: [PHQuery : String] = [:]
    
    // Notification ID
    let notificationID: String
    
    // Constants for not. dispatches
    private let kPlayerStatePlaying: [String]
    
    // Playback position query field
    static let pField = "[position]"
    
    // Acces the AppleScript bridge
    let appleScriptBridge = AppleScriptBridge.shared
    
    init(notificationID: String, kPlayerStatePlaying: [String], queries: [PHQuery : String]) {
        self.notificationID = notificationID
        self.kPlayerStatePlaying = kPlayerStatePlaying
        self.queries = queries
    }
    
    func togglePlayPause() {
        appleScriptBridge.execAppleScript(queries[.togglePlayPause]!)
    }
    
    func nextTrack() {
        appleScriptBridge.execAppleScript(queries[.nextTrack]!)
    }
    
    func previousTrack() {
        appleScriptBridge.execAppleScript(queries[.previousTrack]!)
    }
    
    func currentPlaybackPosition() -> Float? {
        guard let stringValue = appleScriptBridge.execAppleScriptWithOutput(queries[.playbackPosition]!) else { return nil }
        
        return Float(stringValue)
    }
    
    func goTo(time: Float) {
        appleScriptBridge.execAppleScript(queries[.setPlaybackPosition]!.replacingOccurrences(of: PlayerHelper.pField, with: String(time)))
    }
    
    func songFromAppleScriptQuery() -> Song {
        guard   let playbackPosition = appleScriptBridge.execAppleScriptWithOutput(queries[.playbackPosition]!),
                let duration = appleScriptBridge.execAppleScriptWithOutput(queries[.songDuration]!)
        else { return Song() }
        
        guard   let songName = appleScriptBridge.execAppleScriptWithOutput(queries[.songName]!),
                let songArtist = appleScriptBridge.execAppleScriptWithOutput(queries[.songArtist]!),
                let songAlbum = appleScriptBridge.execAppleScriptWithOutput(queries[.songAlbum]!),
            
                let isPlaying = appleScriptBridge.execAppleScriptWithOutput(queries[.playerState]!),
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
