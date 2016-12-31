//
//  PlayersManager.swift
//  Muse
//
//  Created by Marco Albera on 31/12/16.
//  Copyright © 2016 Edge Apps. All rights reserved.
//

// Available players
enum PlayerID {
    case spotify
    case vox
}

typealias PlayersDictionary = [PlayerID: PlayerHelper]

// The players dictionary
let playersDictionary: PlayersDictionary = [.spotify: SpotifyHelper.shared,
                                            .vox: VoxHelper.shared]

// Extend the dictionary with some useful functions
extension Dictionary where Value: PlayerHelper {
    
    // MARK: Extended functions
    
    var designatedPlayer: PlayerHelper {
        // Find the first player that's running and playing
        for (_, helper) in self {
            if helper.isAvailable && helper.isPlaying {
                return helper
            }
        }
        
        // Return Spotify helper by default
        return SpotifyHelper.shared
    }
    
}
