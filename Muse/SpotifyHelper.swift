//
//  SpotifyHelper.swift
//  Muse
//
//  Created by Marco Albera on 21/11/16.
//  Copyright © 2016 Edge Apps. All rights reserved.
//

import Cocoa

class SpotifyHelper : PlayerHelper {
    
    // Singleton constructor
    static let shared = SpotifyHelper()
    
    // Artwork code
    let qArtworkURL = "tell application \"Spotify\"\nartwork url of current track\nend tell"
    
    var artworkURL: String? {
        return appleScriptBridge.execAppleScriptWithOutput(qArtworkURL)
    }
    
    // Make standard init private
    private init() {
        super.init(
            notificationID: "com.spotify.client.PlaybackStateChanged",
            kPlayerStatePlaying: ["Playing", "kPSP"],
            qTogglePlayPause: "tell application \"Spotify\"\nplaypause\nend tell",
            qNextTrack: "tell application \"Spotify\"\nnext track\nend tell",
            qPreviousTrack: "tell application \"Spotify\"\nprevious track\nend tell",
            qPlayerState: "tell application \"Spotify\"\nplayer state\nend tell",
            qPlaybackPosition: "tell application \"Spotify\"\nplayer position\nend tell",
            qSetPlaybackPosition: ["tell application \"Spotify\"\nset player position to ","\nend tell"],
            qSongName: "tell application \"Spotify\"\nname of current track\nend tell",
            qSongAlbum: "tell application \"Spotify\"\nartist of current track\nend tell",
            qSongArtist: "tell application \"Spotify\"\nalbum of current track\nend tell",
            qSongDuration: "tell application \"Spotify\"\nduration of current track\nend tell"
        )
    }
    
}
