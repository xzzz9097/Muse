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

// Default player's id (Spotify)
let defaultPlayerID: PlayerID = .spotify

class PlayersManager {
    
    // MARK: Constructors
    
    static let shared = PlayersManager()
    
    private init() { }
    
    // MARK: Dictionary definitions
    
    typealias PlayersDictionary = [PlayerID: PlayerHelper]
    
    typealias NotificationsDictionary = [PlayerID: NSNotification.Name]
    
    // The players dictionary
    private let players: PlayersDictionary = [.spotify: SpotifyHelper.shared,
                                              .vox: VoxHelper.shared]
    
    // MARK: Interaction functions
    
    func get(_ id: PlayerID) -> PlayerHelper {
        // Return a requested helper
        return players[id]!
    }
    
    // MARK: Player vars
    
    var designatedHelperID: PlayerID {
        // Find the first player that's runninng and playing
        for (id, helper) in players {
            if helper.isAvailable && helper.isPlaying {
                return id
            }
        }
        
        // If there are no running players check for the open one
        for (id, helper) in players {
            if helper.isAvailable {
                return id
            }
        }
        
        // Return default helper otherwise
        return defaultPlayerID
    }
    
    var designatedHelper: PlayerHelper {
        // Returns the currently designated player
        return get(designatedHelperID)
    }
    
    var defaultHelper: PlayerHelper {
        // Returns the default player
        return get(defaultPlayerID)
    }
    
    var TrackChangedNotifications: NotificationsDictionary {
        var notifications: NotificationsDictionary = [ : ]
        
        for (id, player) in players {
            notifications[id] = player.TrackChangedNotification
        }
        
        return notifications
    }
    
}
