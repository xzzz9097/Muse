//
//  ViewController.swift
//  Muse
//
//  Created by Marco Albera on 21/11/16.
//  Copyright © 2016 Edge Apps. All rights reserved.
//

import Cocoa

@available(OSX 10.12.2, *)
class ViewController: NSViewController {
    
    let spotifyHelper = SpotifyHelper.shared

    @IBOutlet weak var fullSongArtworkView: ImageView!
    
    @IBOutlet weak var titleLabelView: NSTextField!
    @IBOutlet weak var albumArtistLabelView: NSTextField!
    
    @IBOutlet weak var previousTrackButton: NSButton!
    @IBOutlet weak var togglePlayPauseButton: NSButton!
    @IBOutlet weak var nextTrackButton: NSButton!
    
    @IBOutlet weak var songProgressSlider: NSSlider!
    
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
    
    @IBAction func songProgressSliderValueChanged(_ sender: Any) {
        // Track progress slider changes
        if let slider = sender as? NSSlider {
            guard let currentEvent = NSApplication.shared().currentEvent else { return }
            
            if (currentEvent.type == .leftMouseDown) {
                // Detected mouse down
                spotifyHelper.scrub(touching: true)
            }
            
            if (currentEvent.type == .leftMouseUp) {
                // Detected mouse up
                spotifyHelper.scrub(to: slider.doubleValue)
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        titleAlbumArtistSuperview = titleLabelView.superview
        
        titleAlbumArtistSuperview.wantsLayer = true
        
        controlsSuperview = togglePlayPauseButton.superview
    }
    
    override func viewWillAppear() {
        setBackgroundAndShadowForSuperView(titleAlbumArtistSuperview)
        
        setBackgroundAndShadowForSuperView(controlsSuperview)
        
        prepareSongProgressSlider()
        
        prepareFullSongArtworkView()
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    func setBackgroundAndShadowForSuperView(_ superview: NSView!) {
        guard let layer = superview.layer else { return }
        
        // Set background color
        layer.backgroundColor = NSColor.controlColor.cgColor
        
        // Set transparency
        layer.opacity = 0.97
        
        // Create shadow
        superview.shadow = NSShadow()
        layer.shadowColor = NSColor.controlShadowColor.cgColor
        layer.shadowRadius = 0.5
        layer.shadowOpacity = 1
    }
    
    func updateButtons(for song: Song) {
        // Initialize playback control buttons
        previousTrackButton.image = NSImage(named: NSImageNameTouchBarRewindTemplate)
        togglePlayPauseButton.image = song.isPlaying ? NSImage(named: NSImageNameTouchBarPauseTemplate) :
                                                       NSImage(named: NSImageNameTouchBarPlayTemplate)
        nextTrackButton.image = NSImage(named: NSImageNameTouchBarFastForwardTemplate)
    }
    
    func prepareSongProgressSlider() {
        guard let cell = self.songProgressSlider.cell as? SliderCell else { return }
        
        // Hide slider thumb
        cell.knobImage = NSImage()
        cell.knobVisible = false
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

