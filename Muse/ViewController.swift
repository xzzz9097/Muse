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
    
    // Button images dictionary
    var actionImages: [PlayerAction: NSImage] = [.previous:  NSImage.previous!,
                                                 .play:      NSImage.play!,
                                                 .pause:     NSImage.pause!,
                                                 .next:      NSImage.next!,
                                                 .shuffling: .shuffling,
                                                 .repeating: .repeating,
                                                 .like:      .like]
    
    // Action view auto close
    let actionViewTimeout:        TimeInterval = 1       // Timeout in seconds
    var actionViewAutoCloseTimer: Timer        = Timer() // The timer
    
    // Title view auto close
    let titleViewTimeout:         TimeInterval = 2       // Timeout in seconds
    var titleViewAutoCloseTimer:  Timer = Timer()        // The timer
    
    // Preferences
    let shouldPeekControls = true  // Hide/show controls on mouse hover
    let shouldShowArtist   = false // Show artist in title popup view
    
    var shouldShowActionBar = true {
        didSet {
            showActionBarView()
        }
    }
    
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
    @IBOutlet weak var titleTextField:        NSTextField!
    @IBOutlet weak var songProgressBar:       NSSlider!
    @IBOutlet weak var likeButton:            NSButton!
    @IBOutlet weak var shuffleButton:         NSButton!
    @IBOutlet weak var repeatButton:          NSButton!
    @IBOutlet var      actionTabView:         NSTabView!
    @IBOutlet weak var actionPlayButton:      NSButton!
    @IBOutlet weak var actionPreviousButton:  NSButton!
    @IBOutlet weak var actionNextButton:      NSButton!
    @IBOutlet weak var actionTabViewHeight:   NSLayoutConstraint!
    
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
        
        actionTabView.translatesAutoresizingMaskIntoConstraints = true
        
        [titleAlbumArtistSuperview,
         controlsSuperview,
         actionSuperview,
         titleSuperview,
         actionTabView].forEach { $0?.wantsLayer = true }
        
        showActionBarView()
    }
    
    override func viewWillAppear() {
        setBackgroundAndShadow(for: titleAlbumArtistSuperview)
        setBackgroundAndShadow(for: controlsSuperview)
        
        prepareSongProgressSlider()
        prepareSongProgressBar()
        prepareFullSongArtworkView()
        prepareLastActionView()
        prepareActionBarButtons()
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
        cell.knobImage   = NSImage()
        cell.knobVisible = false
    }
    
    func prepareSongProgressBar() {
        guard let cell = self.songProgressBar.cell as? SliderCell else { return }
        
        // Customize slider thumb
        cell.width       = view.frame.width
        cell.knobWidth   = 2.0
        cell.height      = 11.0
        
        // Remove corner radius
        cell.radius = 0
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
        
        // Change progress bar height
        actionTabViewHeight.animator().constant = hidden ? 2 : 11
        
        // Hide overlay views
        if !actionSuperview.isHidden { actionSuperview.animator().isHidden = !hidden }
        if !titleSuperview.isHidden  { titleSuperview.animator().isHidden  = !hidden }
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
    
    func prepareActionBarButtons() {
        [likeButton, shuffleButton, repeatButton, actionPlayButton, actionPreviousButton, actionNextButton].forEach {
            $0?.imagePosition       = .imageOnly
            $0?.isBordered          = false
            $0?.layer?.cornerRadius = 4.0
        }
        
        likeButton.action    = #selector(WindowController.likeButtonClicked(_:))
        shuffleButton.action = #selector(WindowController.shuffleButtonClicked(_:))
        repeatButton.action  = #selector(WindowController.repeatButtonClicked(_:))
        
        actionPlayButton.action     = #selector(togglePlayPauseButtonClicked(_:))
        actionPreviousButton.action = #selector(previousTrackButtonClicked(_:))
        actionNextButton.action     = #selector(nextTrackButtonClicked(_:))
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
        titleViewAutoCloseTimer = Timer.scheduledTimer(withTimeInterval: titleViewTimeout,
                                                       repeats: false) { timer in
            // Hide the view and invalidate the timer
            self.titleSuperview.animator().isHidden = true
            timer.invalidate()
        }
    }
    
    func showLastActionView(for action:  PlayerAction,
                            to time:     Double = 0,
                            shouldClose: Bool = true,
                            liked:       Bool = false) {
        // Only show action info if mouse is not hovering
        guard ( controlsSuperview.isHidden ||
                action == .repeating       ||
                action == .shuffling       ||
                action == .scrubbing ) else { return }
        
        // Invalidate existing timers
        // This prevents calls from precedent ones
        actionViewAutoCloseTimer.invalidate()
        
        actionImageView.image = actionImages[action]
        
        // TODO: more testing
        switch action {
        case .shuffling, .repeating, .like:
            var shouldTint = false
            
            // Determine if we should tint the action image with light gray
            // to highlight off state for the action
            // TODO: more visible highlighting method
            switch action {
            case .shuffling: shouldTint = !helper.shuffling
            case .repeating: shouldTint = !helper.repeating
            case .like:      shouldTint = !liked
            default: break
            }
            
            // Tint the image
            if shouldTint {
                actionImageView.image = actionImages[action]?.tint(with: .lightGray)
            }
        case .scrubbing:
            // Hide image view if scrubbing
            actionImageView.isHidden = true
            
            // Set the string value formatted as MM:SS
            actionTextField.stringValue = time.secondsToMMSSString
        default:
            break
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
    
    func showActionBarView() {
        view.toggleSubviewVisibilityAndResize(subview: actionTabView,
                                              visible: shouldShowActionBar)
        
        // Setup action bar buttons and colors
        if shouldShowActionBar {
            prepareActionBarButtons()
            colorActionBar(background: titleSuperview.layer?.backgroundColor,
                           highlight: (songProgressBar.cell as! SliderCell).highlightColor)
        }
        
        fullSongArtworkView.mouseTrackingArea = nil
    }
    
    // MARK: UI refresh
    
    func updateButtons() {
        // Initialize playback control buttons
        previousTrackButton.image   = actionImages[.previous]
        togglePlayPauseButton.image = helper.isPlaying ?
                                      actionImages[.pause] : actionImages[.play]
        nextTrackButton.image       = actionImages[.next]
        
        likeButton.image            = actionImages[.like]?.resized(to: NSMakeSize(15, 15))
        shuffleButton.image         = actionImages[.shuffling]?.resized(to: NSMakeSize(20, 20))
        repeatButton.image          = actionImages[.repeating]?.resized(to: NSMakeSize(20, 20))
        
        actionPlayButton.image      = helper.isPlaying ?
                                      actionImages[.pause]?.resized(to: NSMakeSize(7, 7)) :
                                      actionImages[.play]?.resized(to: NSMakeSize(8, 8))
        actionPreviousButton.image  = actionImages[.previous]?.resized(to: NSMakeSize(12, 12))
        actionNextButton.image      = actionImages[.next]?.resized(to: NSMakeSize(12, 12))
    }
    
    func updateShuffleRepeatButtons() {
        [shuffleButton, repeatButton].enumerated().forEach {
            let enabled        = $0.offset == 0 ? helper.shuffling : helper.repeating
            let alpha: CGFloat = enabled        ?                1 : 0.25
            
            $0.element?.layer?.backgroundColor = $0.element?.layer?.backgroundColor?
                .copy(alpha: alpha)
        }
    }
    
    func updateLikeButton(liked: Bool) {
        likeButton.layer?.backgroundColor = likeButton.layer?.backgroundColor?.copy(alpha: liked ? 1 : 0.25)
    }
    
    func updateFullSongArtworkView(with object: Any?) {
        // Update the artwork view with an image URL
        if let url = object as? URL {
            fullSongArtworkView.loadImage(from: url, fallback: .defaultBg, callback: { _ in })
        // Or an NSImage
        } else if let image = object as? NSImage {
            fullSongArtworkView.image = image
        }
        
        // If the image is not square we cut it instead of stretching it
        if  let image = fullSongArtworkView.image,
            image.size.width != image.size.height {
            fullSongArtworkView.image = image.resized(
                to: NSMakeSize(fullSongArtworkView.frame.width,
                               fullSongArtworkView.frame.height)
            )
        }
    }
    
    func colorButtonImages(with color: NSColor) {
        // Update button images with new color
        actionImages = actionImages.mapValues { $0.tint(with: color) }
        
        // Color action image too
        actionImageView.image = actionImageView.image?.tint(with: color)
    }
    
    func colorViews(with colors: ImageColors) {
        // Blend all colors with 50% of lightGray to avoid too contrasty views
        let colors = [ colors.background, colors.primary, colors.secondary, colors.detail ]
                .map { $0?.blended(withFraction: 0.5, of: .lightGray) }
        
        guard   let backgroundColor = colors[0],
                let primaryColor    = colors[1],
                var secondaryColor  = colors[2],
                let detailColor     = colors[3] else { return }
        
        // Pick the more contrasting color compared to primary between secondary and detail
        secondaryColor = secondaryColor.distance(from: primaryColor) >
                            detailColor.distance(from: primaryColor) ? secondaryColor : detailColor
        
        var highlightColor = secondaryColor
        
        // Hotfix for unreadable slider highlight when I and II color are too similar
        // We blend the highlight color with light or dark gray,
        // for dark or light primary color respectively
        if highlightColor.distance(from: primaryColor) < 0.02 {
            if  highlightColor.isDarkColor {
                highlightColor = secondaryColor.blended(withFraction: 0.5, of: .lightGray)!
            } else {
                highlightColor = secondaryColor.blended(withFraction: 0.5, of: .darkGray)!
            }
        }
        
        // Set the superviews background color and animate it
        [ titleAlbumArtistSuperview, controlsSuperview, actionSuperview, titleSuperview, actionTabView ].forEach {
            $0?.layer?.animateChange(to: backgroundColor.cgColor,
                                     for: CALayer.kBackgroundColorPath)
        }
        
        // Set the text colors
        [ titleLabelView, actionTextField, titleTextField ].forEach {
            $0?.textColor = primaryColor
        }
        albumArtistLabelView.textColor = secondaryColor
        
        // Set color on the slider too
        if let sliderCell = songProgressSlider.cell as? SliderCell {
            sliderCell.backgroundColor = primaryColor
            sliderCell.highlightColor  = highlightColor
        }
        
        // And on the progress bar
        if let barCell = songProgressBar.cell as? SliderCell {
            barCell.backgroundColor = primaryColor
            barCell.highlightColor  = highlightColor
            barCell.knobColor       = backgroundColor
        }
        
        // Set the color on the playback buttons
        colorButtonImages(with: primaryColor)
        updateButtons()
        
        colorActionBar(highlight: highlightColor)
    }
    
    func colorActionBar(background: CGColor? = nil,
                        highlight: NSColor? = nil) {
        if let backgroundColor = background {
            actionTabView.layer?.backgroundColor = backgroundColor
        }
        
        if let highlightColor = highlight {
            [likeButton, shuffleButton, repeatButton].forEach {
                var alpha: CGFloat = 0.25
                
                // Check current alpha value before setting a new one
                if  let currentAlpha = $0?.layer?.backgroundColor?.alpha {
                    alpha = currentAlpha
                }
                
                $0?.layer?.backgroundColor = highlightColor.cgColor.copy(alpha: alpha)
            }
            
            [actionPlayButton, actionPreviousButton, actionNextButton].forEach {
                $0?.layer?.backgroundColor = highlightColor.cgColor
            }
        }
    }
    
    func updateTitleAlbumArtistView(for song: Song) {
        titleLabelView.stringValue = song.name
        
        // ALso update title on popup view
        titleTextField.stringValue = shouldShowArtist ?
                                     "\(song.name) - \(song.artist)" :
                                     song.name
        
        albumArtistLabelView.stringValue = "\(song.artist) - \(song.album)"
    }
    
    func updateSongProgressSlider(with position: Double) {
        // Update slider
        songProgressSlider.doubleValue = position
        
        // Update always on progress bar
        songProgressBar.doubleValue = position
    }
    
}

