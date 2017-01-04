//
//  ViewController.swift
//  Muse
//
//  Created by Marco Albera on 21/11/16.
//  Copyright © 2016 Edge Apps. All rights reserved.
//

import Cocoa
import QuartzCore

@available(OSX 10.12.2, *)
class ViewController: NSViewController {
    
    // MARK: Helpers
    
    var helper: PlayerHelper {
        guard let window = self.view.window, let windowController = window.windowController as? WindowController else {
            // Default helper
            return PlayersManager.shared.defaultHelper
        }
        
        // Returns helper from WindowController
        // TODO: Move helper outside WC
        return windowController.helper
    }
    
    // MARK: Outlets

    @IBOutlet weak var fullSongArtworkView: ImageView!
    
    @IBOutlet weak var titleLabelView: NSTextField!
    @IBOutlet weak var albumArtistLabelView: NSTextField!
    
    @IBOutlet weak var previousTrackButton: NSButton!
    @IBOutlet weak var togglePlayPauseButton: NSButton!
    @IBOutlet weak var nextTrackButton: NSButton!
    
    @IBOutlet weak var songProgressSlider: NSSlider!
    
    // MARK: Superviews
    
    var titleAlbumArtistSuperview: NSView!
    var controlsSuperview: NSView!
    
    // MARK: Actions
    
    @IBAction func previousTrackButtonClicked(_ sender: Any) {
        helper.previousTrack()
    }
    
    @IBAction func togglePlayPauseButtonClicked(_ sender: Any) {
        helper.togglePlayPause()
    }
    
    @IBAction func nextTrackButtonClicked(_ sender: Any) {
        helper.nextTrack()
    }
    
    @IBAction func songProgressSliderValueChanged(_ sender: Any) {
        // Track progress slider changes
        if let slider = sender as? NSSlider {
            guard let currentEvent = NSApplication.shared().currentEvent else { return }
            
            if (currentEvent.type == .leftMouseDown) {
                // Detected mouse down
                helper.scrub(touching: true)
            }
            
            if (currentEvent.type == .leftMouseUp) {
                // Detected mouse up
                helper.scrub(to: slider.doubleValue)
            }
        }
    }
    
    // MARK: UI preparation
    
    override func viewDidLoad() {
        super.viewDidLoad()

        titleAlbumArtistSuperview = titleLabelView.superview
        titleAlbumArtistSuperview.wantsLayer = true
        
        controlsSuperview = togglePlayPauseButton.superview
        controlsSuperview.wantsLayer = true
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
        
        // Create shadow
        superview.shadow = NSShadow()
        layer.shadowColor = NSColor.controlShadowColor.cgColor
        layer.shadowRadius = 0.5
        layer.shadowOpacity = 1
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
    
    // MARK: UI refresh
    
    func updateButtons() {
        // Initialize playback control buttons
        previousTrackButton.image = .previous
        togglePlayPauseButton.image = helper.isPlaying ? .pause : .play
        nextTrackButton.image = .next
    }
    
    func updateFullSongArtworkView(with object: Any?) {
        // Update the artwork view with an image URL
        if let url = object as? URL {
            fullSongArtworkView.loadImage(from: url, callback: { _ in })
        // Or an NSImage
        } else if let image = object as? NSImage {
            fullSongArtworkView.image = image
        }
        
        guard let image = fullSongArtworkView.image else { return }
        
        // Update the colors with a completion handler
        // This avoids blocking the main UI thread
        image.getColors { colors in
            self.colorViews(with: colors)
        }
    }
    
    func colorViews(with colors: ImageColors) {
        // Blend the background color with 'lightGray'
        // This prevents view from getting too dark
        let backgroundColor = colors.background.blended(withFraction: 0.5, of: .lightGray)?.cgColor
        let primaryColor = colors.primary.blended(withFraction: 0.5, of: .lightGray)
        let secondaryColor = colors.secondary.blended(withFraction: 0.5, of: .lightGray)
        
        animateColorChange(on: titleAlbumArtistSuperview.layer!, to: backgroundColor!)
        animateColorChange(on: controlsSuperview.layer!, to: backgroundColor!)
        
        // Set the text colors
        titleLabelView.textColor = primaryColor
        albumArtistLabelView.textColor = secondaryColor
        
        // Set color on the slider too
        if let cell = songProgressSlider.cell as? SliderCell {
            cell.backgroundColor = primaryColor!
            cell.highlightColor = secondaryColor!
        }
    }
    
    func animateColorChange(on layer: CALayer, to value: CGColor) {
        let kBackgroundColorAnimation = "backgroundColor"
        
        let animation = CABasicAnimation(keyPath: kBackgroundColorAnimation)
        
        CATransaction.begin()
        CATransaction.setCompletionBlock {
            layer.backgroundColor = value
        }
        
        animation.fromValue = layer.backgroundColor
        animation.toValue   = value
        
        layer.add(animation, forKey: kBackgroundColorAnimation)
        
        CATransaction.commit()
    }
    
    func updateTitleAlbumArtistView(for song: Song) {
        titleLabelView.stringValue = song.name
        
        albumArtistLabelView.stringValue = "\(song.artist) - \(song.album)"
    }
    
    func updateSongProgressSlider(with position: Double) {
        songProgressSlider.doubleValue = position
    }
    
}

