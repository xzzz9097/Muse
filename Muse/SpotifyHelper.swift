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
            queries: [.togglePlayPause: "tell application \"Spotify\"\nplaypause\nend tell",
                      .nextTrack: "tell application \"Spotify\"\nnext track\nend tell",
                      .previousTrack: "tell application \"Spotify\"\nprevious track\nend tell",
                      .playerState: "tell application \"Spotify\"\nplayer state\nend tell",
                      .playbackPosition: "tell application \"Spotify\"\nplayer position\nend tell",
                      .setPlaybackPosition: "tell application \"Spotify\"\nset player position to \(PlayerHelper.pField)\nend tell",
                      .songName: "tell application \"Spotify\"\nname of current track\nend tell",
                      .songArtist: "tell application \"Spotify\"\nartist of current track\nend tell",
                      .songAlbum: "tell application \"Spotify\"\nalbum of current track\nend tell",
                      .songDuration: "tell application \"Spotify\"\nduration of current track\nend tell"]
        )
    }
    
}
