//
//  PlayerStates.h
//  Muse
//
//  Created by Marco Albera on 07/12/16.
//  Copyright © 2016 Edge Apps. All rights reserved.
//

#ifndef PlayerStates_h
#define PlayerStates_h

/* Spotify player states enum */
// Obj-C definition is required to create
// a type compatible with Spotify AS output
typedef enum {
    SpotifyPlayerStatePlaying = 'kPSP',
    SpotifyPlayerStatePaused = 'kPSp',
    SpotifyPlayerStateStopped = 'kPSS'
} SpotifyPlayerState;

#endif /* PlayerStates_h */
