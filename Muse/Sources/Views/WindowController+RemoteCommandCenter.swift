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
    
    // MARK: TouchBar main playback controls
    // Callbacks for play, pause and play/pause that also
    // manually refresh playbackState in infoCenter
    
    /**
     Handles system play requests and the start of scrub event
     */
    func handlePlay(event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {
        helper.play()
        
        nowPlayingInfoCenter.playbackState = .playing
        
        return .success
    }
    
    /**
     Handles system pause requests and the end of scrub event
     */
    func handlePause(event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {
        helper.pause()
        
        nowPlayingInfoCenter.playbackState = .paused
        
        return .success
    }
    
    /**
     Handles system play/pause toggle requests
     */
    func handleTogglePlayPause(event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {
        helper.togglePlayPause()
        
        updatePlaybackState()
        
        return .success
    }
    
    // MARK: TouchBar secondary playback controls
    
    /**
     Handles system scrubbing requests
     */
    func handleChangePlaybackPosition(event: MPChangePlaybackPositionCommandEvent) -> MPRemoteCommandHandlerStatus {
        helper.scrub(to: event.positionTime.rounded() / self.song.duration, touching: false)
        
        return .success
    }
    
    /**
     Handles system previous track requests
     */
    func handlePreviousTrack(event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {
        helper.previousTrack()
        
        return .success
    }
    
    /**
     Handles system next track requests
     */
    func handleNextTrack(event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {
        helper.nextTrack()
        
        return .success
    }
    
    // MARK: TouchBar info preparation
    
    func prepareRemoteCommandCenter() {
        // Play/pause toggle
        remoteCommandCenter.playCommand.activate(self, action: #selector(handlePlay(event:)))
        remoteCommandCenter.pauseCommand.activate(self, action: #selector(handlePause(event:)))
        remoteCommandCenter.togglePlayPauseCommand.activate(self, action: #selector(handleTogglePlayPause(event:)))
        
        // Previous/next track toggle
        // These work only on 10.12.2+
        remoteCommandCenter.previousTrackCommand.activate(self, action: #selector(handlePreviousTrack(event:)))
        remoteCommandCenter.nextTrackCommand.activate(self, action: #selector(handleNextTrack(event:)))
        
        // Scrub bar control
        remoteCommandCenter.changePlaybackPositionCommand.activate(self, action: #selector(handleChangePlaybackPosition(event:)))
    }
    
    // MARK: TouchBar info refresh
    
    func updateNowPlayingInfo() {
        // First reset the playback state
        // This fixes occasional stuck progress bar after track end
        nowPlayingInfoCenter.playbackState = .interrupted
        
        updatePlaybackState()
        
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
    
    func updatePlaybackState() {
        nowPlayingInfoCenter.playbackState = helper.isPlaying ? .playing : .paused
    }
    
}
