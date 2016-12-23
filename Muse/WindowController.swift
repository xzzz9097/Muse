//
//  WindowController.swift
//  Muse
//
//  Created by Marco Albera on 21/11/16.
//  Copyright © 2016 Edge Apps. All rights reserved.
//

import Cocoa
import Carbon.HIToolbox
import MediaPlayer

@available(OSX 10.12.2, *)
class WindowController: NSWindowController, NSWindowDelegate {
    
    // MARK: Helpers
    
    var spotifyHelper        = SpotifyHelper.shared
    let nowPlayingInfoCenter = MPNowPlayingInfoCenter.default()
    let remoteCommandCenter  = MPRemoteCommandCenter.shared()
    
    // MARK: Runtime properties
    
    var song                           = Song()
    var nowPlayingInfo: [String : Any] = [:]
    var autoCloseCounter               = 0
    
    // MARK: Timers
    
    var songTrackingTimer = Timer()
    var autoCloseTimer    = Timer()
    
    // MARK: Keys
    
    let kSong = "song"

    // MARK: Outlets
    
    @IBOutlet weak var songArtworkView: NSButton!
    @IBOutlet weak var songTitleLabel: NSTextField!
    @IBOutlet weak var songProgressSlider: NSSlider!
    
    @IBOutlet weak var controlsSegmentedView: NSSegmentedControl!
    
    @IBOutlet weak var soundPopoverButton: NSPopoverTouchBarItem!
    
    @IBOutlet weak var soundSlider: NSSliderTouchBarItem!
    
    @IBOutlet weak var shuffleRepeatSegmentedView: NSSegmentedControl!
    
    var isSliding = false
    
    // MARK: Actions
    
    @IBAction func controlsSegmentedViewClicked(_ sender: Any) {
        guard let segmentedControl = sender as? NSSegmentedControl else { return }
        
        switch segmentedControl.selectedSegment {
        case 0:
            spotifyHelper.previousTrack()
        case 1:
            spotifyHelper.togglePlayPause()
        case 2:
            spotifyHelper.nextTrack()
        default:
            return
        }
    }
    
    @IBAction func shuffleRepeatSegmentedViewClicked(_ sender: Any) {
        guard let segmentedControl = sender as? NSSegmentedControl else { return }
        
        let selectedSegment = segmentedControl.selectedSegment
        
        switch selectedSegment {
        case 0:
            // Toggle shuffling
            spotifyHelper.shuffling = segmentedControl.isSelected(forSegment: selectedSegment)
        case 1:
            // Toggle repeating
            spotifyHelper.repeating = segmentedControl.isSelected(forSegment: selectedSegment)
        default:
            return
        }
    }
    
    @IBAction func progressSliderValueChanged(_ sender: Any) {
        // Track progress slider changes
        if let slider = sender as? NSSlider {
            guard let currentEvent = NSApplication.shared().currentEvent else { return }
            
            for _ in (currentEvent.touches(matching: NSTouchPhase.began, in: slider)) {
                // Detected touch phase start
                spotifyHelper.scrub(touching: true)
            }
            
            for _ in (currentEvent.touches(matching: NSTouchPhase.ended, in: slider)) {
                // Detected touch phase end
                spotifyHelper.scrub(to: slider.doubleValue)
            }
        }
    }
    
    @IBAction func soundSliderValueChanged(_ sender: Any) {
        guard let sliderItem = sender as? NSSliderTouchBarItem else { return }
        
        // Set the volume on the player
        spotifyHelper.volume = sliderItem.slider.integerValue
        
        updateSoundPopoverButton(for: spotifyHelper.volume)
    }
    
    @IBAction func songArtworkViewClicked(_ sender: Any) {
        // Jump to player when the artwork on the TouchBar is tapped
        showPlayer()
    }
    
    // MARK: Key handlers
    
    override func keyDown(with event: NSEvent) {
        // Catch key events
        switch Int(event.keyCode) {
        case kVK_Escape:
            guard let window = self.window else { return }
            toggleWindow(window, visible: false)
        case kVK_LeftArrow, kVK_ANSI_A:
            spotifyHelper.previousTrack()
        case kVK_Space, kVK_ANSI_S:
            spotifyHelper.togglePlayPause()
        case kVK_RightArrow, kVK_ANSI_D:
            spotifyHelper.nextTrack()
        case kVK_Return, kVK_ANSI_W:
            showPlayer()
        default:
            super.keyDown(with: event)
        }
    }
    
    func registerHotkey() {
        guard let hotkeyCenter = DDHotKeyCenter.shared() else { return }
        
        let modifiers: UInt = NSEventModifierFlags.control.rawValue | NSEventModifierFlags.command.rawValue
        
        // Register system-wide summon hotkey
        hotkeyCenter.registerHotKey(withKeyCode: UInt16(kVK_ANSI_S),
                                    modifierFlags: modifiers,
                                    target: self,
                                    action: #selector(hotkeyAction),
                                    object: nil)
    }
    
    func hotkeyAction() {
        guard let window = self.window else { return }
        
        // Hide window if focused, show if not
        toggleWindow(window, visible: !window.isKeyWindow)
    }
    
    func toggleWindow(_ window: NSWindow, visible: Bool) {
        // Toggles window visibility
        // Bringing the older app on top if necessary
        if (visible) {
            window.makeKeyAndOrderFront(self)
            NSApp.activate(ignoringOtherApps: true)
        } else {
            NSApp.hide(self)
        }
    }
    
    func showPlayer() {
        let player = NSRunningApplication.runningApplications(
            withBundleIdentifier: SpotifyHelper.bundleIdentifier
            )[0]
        
        // Takes to the player window
        player.activate(options: .activateIgnoringOtherApps)
    }
    
    // MARK: Callbacks
    
    func registerCallbacks() {
        // Callback for PlayerHelper's nextTrack() and previousTrack()
        spotifyHelper.trackChangedHandler = {
            self.song.playbackPosition = 0
            
            self.updateSongProgressSlider(shouldLoadTime: false)
            
            self.updateNowPlayingInfo()
        }
        
        // Callback for PlayerHelper's goTo(Bool, Double?)
        spotifyHelper.timeChangedHandler  = { touching, doubleValue in
            self.isSliding = touching
            
            guard !self.isSliding, let value = doubleValue else { return }
            
            self.song.playbackPosition = value * self.song.duration
            
            self.updateSongProgressSlider(shouldLoadTime: false)
        }
    }
    
    // MARK: UI preparation
    
    override func windowDidLoad() {
        super.windowDidLoad()
        
        // Initialize our watcher
        initNotificationWatcher()
        
        // Set custom window attributes
        prepareWindow()
        
        prepareButtons()
        prepareSongProgressSlider()
        prepareImageView()
        
        // Register callbacks for PlayerHelper
        registerCallbacks()
        
        // Register our DDHotKey
        registerHotkey()
        
        // Prepare system-wide controls
        prepareRemoteCommandCenter()
        
        // Load song at cold start
        prepareSong()
    }
    
    func windowDidBecomeKey(_ notification: Notification) {
        // Sync progress slider if song is not playing
        if !self.song.isPlaying { syncSongProgressSlider() }
        
        // Sync the sound slider and button
        prepareSoundSlider()
        
        // Sync shuffling and repeating segmented control
        prepareShuffleRepeatSegmentedView()
    }
    
    func prepareWindow() {
        guard let window = self.window else { return }
        
        window.titleVisibility = NSWindowTitleVisibility.hidden;
        window.titlebarAppearsTransparent = true
        window.styleMask.update(with: NSWindowStyleMask.fullSizeContentView)
        
        // Set fixed window position (at the center of the screen)
        window.center()
        window.isMovable = false
        
        // Show on every workspace
        window.collectionBehavior = .transient
        
        // Hide after losing focus
        window.hidesOnDeactivate = true
        
        // Set the delegate
        window.delegate = self
        
        window.makeFirstResponder(self)
    }
    
    func prepareAutoClose() {
        // Timer for auto-close
        autoCloseTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: {
            timer in
            
            self.autoCloseCounter += 1
            
            if self.autoCloseCounter == 10 {
                timer.invalidate()
                
                self.autoCloseCounter = 0
            }
        })
    }
    
    func prepareSong() {
        self.song = spotifyHelper.song
        
        updateUIAfterNotification()
        
        trackSongProgress()
    }
    
    func prepareButtons() {
        self.controlsSegmentedView.setImage(NSImage(named: NSImageNameTouchBarRewindTemplate), forSegment: 0)
        self.controlsSegmentedView.setImage(NSImage(named: NSImageNameTouchBarPlayPauseTemplate), forSegment: 1)
        self.controlsSegmentedView.setImage(NSImage(named: NSImageNameTouchBarFastForwardTemplate), forSegment: 2)
    }
    
    func prepareSongProgressSlider() {
        guard let cell = self.songProgressSlider.cell as? SliderCell else { return }
        
        cell.knobImage = NSImage(named: NSImageNameTouchBarPlayheadTemplate)
    }
    
    func prepareSoundSlider() {
        let volume = spotifyHelper.volume
        
        updateSoundPopoverButton(for: volume)
        
        // Set the player volume on the slider
        soundSlider.slider.integerValue = volume
    }

    func prepareShuffleRepeatSegmentedView() {
        // Select 'shuffle' button
        shuffleRepeatSegmentedView.setSelected(spotifyHelper.shuffling, forSegment: 0)
        
        // Select 'repeat' button
        shuffleRepeatSegmentedView.setSelected(spotifyHelper.repeating, forSegment: 1)
    }
    
    func prepareImageView() {
        self.songArtworkView.wantsLayer = true
        self.songArtworkView.layer?.cornerRadius = 4.0
        self.songArtworkView.layer?.masksToBounds = true
    }
    
    // MARK: Notification handling
    
    func initNotificationWatcher() {
        // Attach the NotificationObserver for Spotify notifications
        DistributedNotificationCenter.default().addObserver(self,
                                       selector: #selector(hookNotification(notification:)),
                                       name: NSNotification.Name(rawValue: spotifyHelper.notificationID),
                                       object: nil)
    }
    
    func deinitNotificationWatcher() {
        // Remove the NotificationObserver
        DistributedNotificationCenter.default().removeObserver(self,
                                          name: NSNotification.Name(rawValue: spotifyHelper.notificationID),
                                          object: nil)
    }
    
    func isClosing(with notification: NSNotification) -> Bool {
        guard let userInfo = notification.userInfo else { return true }
        
        // If the notification has only one item
        // that's the PlayerStateStopped -> player is closing
        return userInfo.count < 2
    }
    
    func hookNotification(notification: NSNotification) {
        // When Spotify is quitted, it sends an NSNotification
        // with only PlayerStateStopped, that causes it to 
        // reopen for being polled by Muse
        // So we detect if the notification is a closing one
        guard !isClosing(with: notification) else {
            // Set placeholder value
            // TODO: update artwork with some blank
            self.song = Song()
            
            // This avoids reopening while playing too
            deinitSongTrackingTimer()
            
            updateUIAfterNotification()
            
            updateSongProgressSlider(shouldLoadTime: false)
            
            return
        }
        
        willChangeValue(forKey: kSong)
        
        // Retrieve new value
        self.song = spotifyHelper.song
        
        didChangeValue(forKey: kSong)
        
        updateUIAfterNotification()
        
        trackSongProgress()
    }
    
    // MARK: Playback progress handling
    
    func trackSongProgress() {
        if songTrackingTimer.isValid { deinitSongTrackingTimer() }
        
        if song.isPlaying {
            songTrackingTimer = Timer.scheduledTimer(timeInterval: 1,
                                                     target: self,
                                                     selector: #selector(syncSongProgressSlider),
                                                     userInfo: nil,
                                                     repeats: true)
        } else {
            syncSongProgressSlider()
        }
    }
    
    func deinitSongTrackingTimer() {
        // Invalidates the progress timer
        // e.g. when switching to a different song or on app close
        songTrackingTimer.invalidate()
    }
    
    func updateSongProgressSlider(shouldLoadTime: Bool) {
        if !isSliding {
            if shouldLoadTime {
                self.song.playbackPosition = spotifyHelper.playbackPosition
                
                if self.song.playbackPosition > self.song.duration && self.song.duration == 0 {
                    // Hotfix for occasional song loading errors
                    self.song = spotifyHelper.song
                }
            }
            
            songProgressSlider.doubleValue = self.song.playbackPosition / self.song.duration
            
            // Also update native touchbar scrubber
            updateNowPlayingInfoElapsedPlaybackTime()
            
            // And the View's slider
            guard let viewController = self.contentViewController as? ViewController else { return }
            
            viewController.updateSongProgressSlider(for: self.song)
        }
    }
    
    func syncSongProgressSlider() {
        // Convenience call for updating the progress slider during playback
        updateSongProgressSlider(shouldLoadTime: true)
    }
    
    func updateSoundPopoverButton(for volume: Int) {
        // Change the popover icon based on current volume
        if (volume > 70) {
            soundPopoverButton.collapsedRepresentationImage =
                NSImage(named: NSImageNameTouchBarAudioOutputVolumeHighTemplate)
        } else if (volume > 30) {
            soundPopoverButton.collapsedRepresentationImage =
                NSImage(named: NSImageNameTouchBarAudioOutputVolumeMediumTemplate)
        } else {
            soundPopoverButton.collapsedRepresentationImage =
                NSImage(named: NSImageNameTouchBarAudioOutputVolumeLowTemplate)
        }
    }
    
    // MARK: Deinitialization
    
    func windowWillClose(_ notification: Notification) {
        // Remove the observer when window is closed
        deinitNotificationWatcher()
        
        // Invalidate progress timer
        deinitSongTrackingTimer()
    }
    
    // MARK: UI refresh
    
    func updateUIAfterNotification() {
        updateTouchBarUI()
        
        updateViewUI()
        
        updateNowPlayingInfo()
    }
    
    func updateTouchBarUI() {
        self.songTitleLabel.stringValue = self.song.name
        
        self.controlsSegmentedView.setImage(
            self.song.isPlaying ?
                NSImage(named: NSImageNameTouchBarPauseTemplate) :
                NSImage(named: NSImageNameTouchBarPlayTemplate),
            forSegment: 1
        )
        
        guard   let stringURL = spotifyHelper.artwork() as? String,
                let artworkURL = URL(string: stringURL)
        else { return }
        
        self.songArtworkView.loadImage(from: artworkURL, callback: { image in
            if let viewController = self.contentViewController as? ViewController {
                // Also set image on VC's ImageView after download
                // Faster and more efficient
                viewController.updateFullSongArtworkView(with: image)
            }
        })
    }
    
    func updateViewUI() {
        guard let viewController = self.contentViewController as? ViewController else { return }
        
        viewController.updateTitleAlbumArtistView(for: self.song)
        
        viewController.updateButtons(for: self.song)
    }
    
}
