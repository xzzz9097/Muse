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
    SpotifyEPlSPlaying = 'kPSP',
    SpotifyEPlSPaused = 'kPSp',
    SpotifyEPlSStopped = 'kPSS'
} SpotifyEPlS;

/* Vox player states enum */
typedef NS_ENUM(NSInteger, VoxEPlS) {
    stopped = -1,
    paused = 0,
    playing = 1
};

/* Vox repeat states enum */
typedef NS_ENUM(NSInteger, VoxERpS) {
    none = 0,
    repeatOne = 1,
    repeatAll = 2
};

/* iTunes player states enum */
typedef enum {
    iTunesEPlSStopped = 'kPSS',
    iTunesEPlSPlaying = 'kPSP',
    iTunesEPlSPaused = 'kPSp',
    iTunesEPlSFastForwarding = 'kPSF',
    iTunesEPlSRewinding = 'kPSR'
} iTunesEPlS;

/* iTunes repeat states enum */
typedef enum {
    iTunesERptOff = 'kRpO',
    iTunesERptOne = 'kRp1',
    iTunesERptAll = 'kAll'
} iTunesERpt;

#endif /* PlayerStates_h */
