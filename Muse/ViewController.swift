//
//  ViewController.swift
//  Muse
//
//  Created by Marco Albera on 21/11/16.
//  Copyright © 2016 Edge Apps. All rights reserved.
//

import Cocoa
import QuartzCore

// MARK: ViewController

@available(OSX 10.12.2, *)
class ViewController: NSViewController {
    
    // MARK: Properties
    
    // Button images
    var previousImage = NSImage.previous
    var playImage     = NSImage.play
    var pauseImage    = NSImage.pause
    var nextImage     = NSImage.next
    var shuffleImage  = NSImage.shuffling
    var repeatImage   = NSImage.repeating
    var likeImage     = NSImage.like
    
    // Action view auto close
    let actionViewTimeout:        TimeInterval = 0.75    // Timeout in seconds
    var actionViewAutoCloseTimer: Timer        = Timer() // The timer
    
    // Title view auto close
    let titleViewTImeout:         TimeInterval = 2       // Timeout in seconds
    var titleViewAutoCloseTimer:  Timer = Timer()        // The timer
    
    // Preferences
    let shouldPeekControls = true // Hide/show controls on mouse hover
    
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

    @IBOutlet weak var fullSongArtworkView:   ImageView!
    @IBOutlet weak var titleLabelView:        NSTextField!
    @IBOutlet weak var albumArtistLabelView:  NSTextField!
    @IBOutlet weak var previousTrackButton:   NSButton!
    @IBOutlet weak var togglePlayPauseButton: NSButton!
    @IBOutlet weak var nextTrackButton:       NSButton!
    @IBOutlet weak var songProgressSlider:    NSSlider!
    @IBOutlet weak var actionImageView:       NSImageView!
    @IBOutlet weak var actionTextField:       NSTextField!
    @IBOutlet weak var titleTextField: NSTextField!
    
    // MARK: Superviews
    
    var titleAlbumArtistSuperview: NSView!
    var controlsSuperview:         NSView!
    var actionSuperview:           NSView!
    var titleSuperview:            NSView!
    
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
            
            if currentEvent.type == .leftMouseDragged {
                // Detected mouse down
                helper.scrub(to: slider.doubleValue, touching: true)
            }
            
            if currentEvent.type == .leftMouseUp {
                // Detected mouse up
                helper.scrub(to: slider.doubleValue)
            }
        }
    }
    
    // MARK: UI preparation
    
    override func viewDidLoad() {
        super.viewDidLoad()

        titleAlbumArtistSuperview = titleLabelView.superview
        controlsSuperview         = togglePlayPauseButton.superview
        actionSuperview           = actionImageView.superview
        titleSuperview            = titleTextField.superview
        
        titleAlbumArtistSuperview.wantsLayer = true
        controlsSuperview.wantsLayer         = true
        actionSuperview.wantsLayer           = true
        titleSuperview.wantsLayer            = true
    }
    
    override func viewWillAppear() {
        setBackgroundAndShadow(for: titleAlbumArtistSuperview)
        setBackgroundAndShadow(for: controlsSuperview)
        
        prepareSongProgressSlider()
        prepareFullSongArtworkView()
        prepareLastActionView()
        prepareTitleView()
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    func setBackgroundAndShadow(for superview: NSView!) {
        guard let layer = superview.layer else { return }
        
        // Set background color
        layer.backgroundColor = NSColor.controlColor.cgColor
        
        // Set the shadow
        superview.shadow = NSShadow()
        setShadow(for: layer)
    }
    
    func setShadow(for layer: CALayer) {
        // Create shadow
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
        
        guard self.shouldPeekControls else { return }
        
        setControlViews(hidden: true)
        
        // Add callback to show/hide views when hovering (animating)
        fullSongArtworkView.mouseHandler = { (mouseHovering: Bool) -> Void in
            self.setControlViews(hidden: !mouseHovering)
        }
    }
    
    func setControlViews(hidden: Bool) {
        // Toggles visibility on popup views
        titleAlbumArtistSuperview.animator().isHidden = hidden
        controlsSuperview.animator().isHidden         = hidden
    }
    
    func prepareLastActionView() {
        guard let layer = actionSuperview.layer else { return }
        
        // Set radius
        layer.cornerRadius = 7.5
        layer.masksToBounds = true
        
        // Set shadow
        actionSuperview.shadow = NSShadow()
        setShadow(for: layer)
    }
    
    func prepareTitleView() {
        guard let layer = titleSuperview.layer else { return }
        
        // Set radius
        layer.cornerRadius = 7.5
        layer.masksToBounds = true
    }
    
    // MARK: UI activation
    
    func showTitleView(shouldClose: Bool = true) {
        // Only show title info if mouse is not hovering
        guard controlsSuperview.isHidden else { return }
        
        // Invalidate existing timers
        // This prevents calls form precedent ones
        titleViewAutoCloseTimer.invalidate()
        
        // Show the view
        titleSuperview.animator().isHidden = false
        
        // This keeps time info visible while sliding
        guard shouldClose else { return }
        
        // Restart the autoclose timer
        titleViewAutoCloseTimer = Timer.scheduledTimer(withTimeInterval: titleViewTImeout,
                                              repeats: false) { timer in
            // Hide the view and invalidate the timer
            self.titleSuperview.animator().isHidden = true
            timer.invalidate()
        }
    }
    
    func showLastActionView(for action: PlayerAction, to time: Double = 0, shouldClose: Bool = true) {
        // Only show action info if mouse is not hovering
        guard (controlsSuperview.isHidden || action == .repeating || action == .shuffling || action == .scrubbing) else { return }
        
        // Invalidate existing timers
        // This prevents calls from precedent ones
        actionViewAutoCloseTimer.invalidate()
        
        switch action {
        case .play:
            actionImageView.image = playImage
        case .pause:
            actionImageView.image = pauseImage
        case .previous:
            actionImageView.image = previousImage
        case .next:
            actionImageView.image = nextImage
        case .shuffling:
            if helper.shuffling {
                actionImageView.image = shuffleImage
            } else {
                // Let the user know if shuffle/repeat is disabled
                // by setting a lighter color on the image
                actionImageView.image = shuffleImage.tint(with: .lightGray)
            }
        case .repeating:
            if helper.repeating {
                actionImageView.image = repeatImage
            } else {
                actionImageView.image = repeatImage.tint(with: .lightGray)
            }
        case .like:
            if helper.liked {
                actionImageView.image = likeImage
            } else {
                actionImageView.image = likeImage.tint(with: .lightGray)
            }
        case .scrubbing:
            // Hide image view if scrubbing
            actionImageView.isHidden = true
            
            // Set the string value formatted as MM:SS
            actionTextField.stringValue = time.secondsToMMSSString
        }
        
        // Show image view if not scrubbing
        if action != .scrubbing { actionImageView.isHidden = false }
        
        // Show the view
        actionSuperview.animator().isHidden = false
        
        // This keeps time info visible while sliding
        guard shouldClose else { return }
        
        // Restart the autoclose timer
        actionViewAutoCloseTimer = Timer.scheduledTimer(withTimeInterval: actionViewTimeout,
                                              repeats: false) { timer in
            // Hide the view and invalidate the timer
            self.actionSuperview.animator().isHidden = true
            self.actionTextField.stringValue = ""
            timer.invalidate()
        }
    }
    
    // MARK: UI refresh
    
    func updateButtons() {
        // Initialize playback control buttons
        previousTrackButton.image = previousImage
        togglePlayPauseButton.image = helper.isPlaying ? pauseImage : playImage
        nextTrackButton.image = nextImage
    }
    
    func updateFullSongArtworkView(with object: Any?) {
        // Update the artwork view with an image URL
        if let url = object as? URL {
            fullSongArtworkView.loadImage(from: url, callback: { _ in })
        // Or an NSImage
        } else if let image = object as? NSImage {
            fullSongArtworkView.image = image
        }
    }
    
    func colorButtonImages(with color: NSColor) {
        // Update button images with new color
        previousImage = previousImage?.tint(with: color)
        playImage     = playImage?.tint(with: color)
        pauseImage    = pauseImage?.tint(with: color)
        nextImage     = nextImage?.tint(with: color)
        shuffleImage  = shuffleImage.tint(with: color)
        repeatImage   = repeatImage.tint(with: color)
        likeImage     = likeImage.tint(with: color)
        
        // Color action image too
        actionImageView.image = actionImageView.image?.tint(with: color)
    }
    
    func colorViews(with colors: ImageColors) {
        // Blend the background color with 'lightGray'
        // This prevents view from getting too dark
        let backgroundColor = colors.background.blended(withFraction: 0.5, of: .lightGray)?.cgColor
        let primaryColor    = colors.primary.blended(withFraction: 0.5, of: .lightGray)
        let secondaryColor  = colors.secondary.blended(withFraction: 0.5, of: .lightGray)
        let buttonColor     = colors.primary.blended(withFraction: 0.5, of: .lightGray)
        
        // Set the superview background color and animate it
        titleAlbumArtistSuperview.layer?.animateChange(to: backgroundColor!,
                                                       for: CALayer.kBackgroundColorPath)
        controlsSuperview.layer?.animateChange(to: backgroundColor!,
                                               for: CALayer.kBackgroundColorPath)
        actionSuperview.layer?.animateChange(to: backgroundColor!,
                                             for: CALayer.kBackgroundColorPath)
        titleSuperview.layer?.animateChange(to: backgroundColor!,
                                             for: CALayer.kBackgroundColorPath)
        
        // Set the text colors
        titleLabelView.textColor       = primaryColor
        albumArtistLabelView.textColor = secondaryColor
        actionTextField.textColor      = primaryColor
        titleTextField.textColor       = primaryColor
        
        // Set color on the slider too
        if let cell = songProgressSlider.cell as? SliderCell {
            cell.backgroundColor = primaryColor!
            cell.highlightColor  = secondaryColor!
        }
        
        // Set the color on the playback buttons
        colorButtonImages(with: buttonColor!)
        updateButtons()
    }
    
    func updateTitleAlbumArtistView(for song: Song) {
        titleLabelView.stringValue = song.name
        
        // ALso update title on popup view
        titleTextField.stringValue = titleLabelView.stringValue
        
        albumArtistLabelView.stringValue = "\(song.artist) - \(song.album)"
    }
    
    func updateSongProgressSlider(with position: Double) {        
        songProgressSlider.doubleValue = position
    }
    
}

