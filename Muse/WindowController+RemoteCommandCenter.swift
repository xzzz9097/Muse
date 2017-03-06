//
//  WindowController+RemoteCommandCenter.swift
//  Muse
//
//  Created by Marco Albera on 04/12/16.
//  Copyright © 2016 Edge Apps. All rights reserved.
//

import Foundation
import MediaPlayer

@available(OSX 10.12.2, *)
extension WindowController {
    
    // MARK: TouchBar playback controls
    
    func togglePlayPause(event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {
        togglePlaybackState(reverse: true)
        
        helper.togglePlayPause()
        
        return .success
    }
    
    func changePlaybackPosition(event: MPChangePlaybackPositionCommandEvent) -> MPRemoteCommandHandlerStatus {
        helper.scrub(to: event.positionTime.rounded() / self.song.duration)
        
        return .success
    }
    
    func previousTrack(event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {
        helper.previousTrack()
        
        return .success
    }
    
    func nextTrack(event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {
        helper.nextTrack()
        
        return .success
    }
    
    // MARK: TouchBar info preparation
    
    func prepareRemoteCommandCenter() {
        // Play/pause toggle
        remoteCommandCenter.playCommand.activate(self, action: #selector(togglePlayPause(event:)))
        remoteCommandCenter.togglePlayPauseCommand.activate(self, action: #selector(togglePlayPause(event:)))
        
        // Previous/next track toggle
        // Apparently these work only on 10.12.2+
        remoteCommandCenter.previousTrackCommand.activate(self, action: #selector(previousTrack(event:)))
        remoteCommandCenter.nextTrackCommand.activate(self, action: #selector(nextTrack(event:)))
        
        // Scrub bar control
        remoteCommandCenter.changePlaybackPositionCommand.activate(self, action: #selector(changePlaybackPosition(event:)))
    }
    
    // MARK: TouchBar info refresh
    
    func updateNowPlayingInfo() {
        // First reset the playback state
        // This fixes occasional stuck progress bar after track end
        nowPlayingInfoCenter.playbackState = .interrupted
        
        togglePlaybackState()
        
        self.nowPlayingInfo = [
            MPMediaItemPropertyTitle: self.song.name,
            MPMediaItemPropertyArtist: self.song.artist,
            MPMediaItemPropertyAlbumTitle: self.song.album,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: helper.playbackPosition,
            MPMediaItemPropertyPlaybackDuration: self.song.duration,
            MPNowPlayingInfoPropertyMediaType: MPNowPlayingInfoMediaType.audio.rawValue
        ]
        
        // MediaPlayer nowPlayingInfo
        nowPlayingInfoCenter.nowPlayingInfo = self.nowPlayingInfo
    }
    
    func updateNowPlayingInfoElapsedPlaybackTime(with position: Double) {
        self.nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = position
        
        nowPlayingInfoCenter.nowPlayingInfo = self.nowPlayingInfo
    }
    
    func togglePlaybackState(reverse: Bool = false) {
        if reverse {
            nowPlayingInfoCenter.playbackState = helper.isPlaying ? .paused : .playing
        } else {
            nowPlayingInfoCenter.playbackState = helper.isPlaying ? .playing : .paused
        }
    }
    
}
