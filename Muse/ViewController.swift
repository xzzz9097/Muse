//
//  ViewController.swift
//  Muse
//
//  Created by Marco Albera on 21/11/16.
//  Copyright © 2016 Edge Apps. All rights reserved.
//

import Cocoa

@available(OSX 10.12.1, *)
class ViewController: NSViewController {
    
    let spotifyHelper = SpotifyHelper.shared

    @IBOutlet weak var fullSongArtworkView: ImageView!
    
    @IBOutlet weak var titleLabelView: NSTextField!
    @IBOutlet weak var albumArtistLabelView: NSTextField!
    
    @IBOutlet weak var previousTrackButton: NSButton!
    @IBOutlet weak var togglePlayPauseButton: NSButton!
    @IBOutlet weak var nextTrackButton: NSButton!
    
    @IBOutlet weak var songProgressSlider: NSSliderCell!
    
    var titleAlbumArtistSuperview: NSView!
    var controlsSuperview: NSView!
    
    @IBAction func previousTrackButtonClicked(_ sender: Any) {
        spotifyHelper.previousTrack()
    }
    
    @IBAction func togglePlayPauseButtonClicked(_ sender: Any) {
        spotifyHelper.togglePlayPause()
    }
    
    @IBAction func nextTrackButtonClicked(_ sender: Any) {
        spotifyHelper.nextTrack()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        titleAlbumArtistSuperview = titleLabelView.superview
        
        titleAlbumArtistSuperview.wantsLayer = true
        
        controlsSuperview = togglePlayPauseButton.superview
    }
    
    override func viewWillAppear() {
        setBackgroundAndShadowForSuperView(titleAlbumArtistSuperview)
        
        setBackgroundAndShadowForSuperView(controlsSuperview, facingUp: true)
        
        prepareFullSongArtworkView()
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    func setBackgroundAndShadowForSuperView(_ superview: NSView!, facingUp: Bool = false) {
        guard let layer = superview.layer else { return }
        
        // Set background color
        layer.backgroundColor = NSColor.controlColor.cgColor
        
        // Set transparency
        layer.opacity = 0.95
        
        // Create shadow
        superview.shadow = NSShadow()
        layer.shadowColor = NSColor.controlShadowColor.cgColor
        layer.shadowRadius = 2.25
        layer.shadowOffset = facingUp ? NSMakeSize(0, 2.0) :
                                        NSMakeSize(0, -2.0)
        layer.shadowOpacity = 0.3
    }
    
    func updateButtons(for song: Song) {
        // Initialize playback control buttons
        previousTrackButton.image = NSImage(named: NSImageNameTouchBarRewindTemplate)
        togglePlayPauseButton.image = song.isPlaying ? NSImage(named: NSImageNameTouchBarPauseTemplate) :
                                                       NSImage(named: NSImageNameTouchBarPlayTemplate)
        nextTrackButton.image = NSImage(named: NSImageNameTouchBarFastForwardTemplate)
    }
    
    func prepareFullSongArtworkView() {
        // Set image scaling
        fullSongArtworkView.imageScaling = .scaleAxesIndependently
        
        // Add callback to show/hide views when hovering (animating)
        fullSongArtworkView.mouseHandler = {
            (mouseHovering: Bool) -> Void in
                self.titleAlbumArtistSuperview.animator().isHidden = !mouseHovering
                self.controlsSuperview.animator().isHidden = !mouseHovering
        }
    }
    
    func updateFullSongArtworkView(for url: URL) {
        fullSongArtworkView.loadImageFromURL(url: url)
    }
    
    func updateTitleAlbumArtistView(for song: Song) {
        titleLabelView.stringValue = song.name
        
        albumArtistLabelView.stringValue = "\(song.artist) - \(song.album)"
    }
    
    func updateSongProgressSlider(for song: Song) {
        songProgressSlider.doubleValue = song.playbackPosition / song.duration
    }
    
}

