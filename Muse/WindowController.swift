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
    
    // MARK: App delegate getter
    
    let delegate = NSApplication.shared().delegate as? AppDelegate
    
    // MARK: Helpers

    let manager: PlayersManager = PlayersManager.shared
    var helper: PlayerHelper    = PlayersManager.shared.designatedHelper
    let nowPlayingInfoCenter    = MPNowPlayingInfoCenter.default()
    let remoteCommandCenter     = MPRemoteCommandCenter.shared()
    
    // MARK: Runtime properties
    
    var song                           = Song()
    var nowPlayingInfo: [String : Any] = [:]
    var autoCloseCounter               = 0
    
    // MARK: Timers
    
    var songTrackingTimer = Timer()
    var autoCloseTimer    = Timer()
    
    // MARK: Keys
    
    let kSong = "song"
    // Constant for enabling title on menuBar
    // should be defined in a preference
    let kShouldSetTitleOnMenuBar = true
    // Constant for setting menu title length
    let kMenuItemMaximumLength = 20

    // MARK: Outlets
    
    @IBOutlet weak var songArtworkTitleButton: NSButton!
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
            helper.previousTrack()
        case 1:
            helper.togglePlayPause()
        case 2:
            helper.nextTrack()
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
            helper.shuffling = segmentedControl.isSelected(forSegment: selectedSegment)
        case 1:
            // Toggle repeating
            helper.repeating = segmentedControl.isSelected(forSegment: selectedSegment)
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
                helper.scrub(touching: true)
            }
            
            for _ in (currentEvent.touches(matching: NSTouchPhase.ended, in: slider)) {
                // Detected touch phase end
                helper.scrub(to: slider.doubleValue)
            }
        }
    }
    
    @IBAction func soundSliderValueChanged(_ sender: Any) {
        guard let sliderItem = sender as? NSSliderTouchBarItem else { return }
        
        // Set the volume on the player
        helper.volume = sliderItem.slider.integerValue
        
        updateSoundPopoverButton(for: helper.volume)
    }
    
    @IBAction func songArtworkTitleButtonClicked(_ sender: Any) {
        // Jump to player when the artwork on the TouchBar is tapped
        showPlayer()
    }
    
    // MARK: Key handlers
    
    override func keyDown(with event: NSEvent) {
        // Catch key events
        switch Int(event.keyCode) {
        case kVK_Escape:
            if let window = self.window { window.setVisibility(false) }
        case kVK_LeftArrow, kVK_ANSI_A:
            helper.previousTrack()
        case kVK_Space, kVK_ANSI_S:
            helper.togglePlayPause()
        case kVK_RightArrow, kVK_ANSI_D:
            helper.nextTrack()
        case kVK_Return, kVK_ANSI_W:
            showPlayer()
        case kVK_ANSI_X:
            helper.shuffling = !helper.shuffling
        case kVK_ANSI_R:
            helper.repeating = !helper.repeating
        case kVK_ANSI_1:
            setPlayerHelper(to: .spotify)
            return
        case kVK_ANSI_2:
            setPlayerHelper(to: .vox)
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
        if let window = self.window { window.toggleVisibility() }
    }
    
    func showPlayer() {
        let player = NSRunningApplication.runningApplications(
            withBundleIdentifier: type(of: helper).BundleIdentifier
            )[0]
        
        // Takes to the player window
        player.activate(options: .activateIgnoringOtherApps)
    }
    
    // MARK: Player loading
    
    func setPlayerHelper(to id: PlayerID) {
        // Stop the old watcher
        deinitNotificationWatcher()
        
        // Set the new player
        helper = manager.get(id)
        
        // Register again the callbacks
        registerCallbacks()
        
        // Initiate the new watcher
        initNotificationWatcher()
        
        // Load the new song
        handleNewSong()
        
        // Update timing
        trackSongProgress()
    }
    
    // MARK: Callbacks
    
    func registerCallbacks() {
        // Callback for PlayerHelper's togglePlayPause()
        helper.playPauseHandler = {
            if !self.helper.doesSendPlayPauseNotification {
                self.handlePlayPause()
                
                self.trackSongProgress()
            }
        }
        
        // Callback for PlayerHelper's nextTrack() and previousTrack()
        helper.trackChangedHandler = {
            self.updateSongProgressSlider(with: 0)
            
            self.updateNowPlayingInfo()
        }
        
        // Callback for PlayerHelper's goTo(Bool, Double?)
        helper.timeChangedHandler = { touching, doubleValue in
            self.isSliding = touching
            
            guard !self.isSliding, let value = doubleValue else { return }
            
            self.updateSongProgressSlider(with: value * self.song.duration)
        }
        
        // Callback for PlayerHelper's shuffe/repeat setters
        helper.shuffleRepeatChangedHandler = {
            // Update shuffleRepeat segmented view with new values
            self.updateShuffleRepeatSegmentedView()
        }
        
        if let window = self.window, let delegate = self.delegate {
            // Callback for AppDelegate window toggled
            delegate.windowToggledHandler = { window.toggleVisibility() }
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
        prepareSongArtworkTitleButton()
        
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
        if !helper.isPlaying { syncSongProgressSlider() }
        
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
        self.song = helper.song
        
        updateAfterNotification()
        
        trackSongProgress()
    }
    
    func prepareButtons() {
        self.controlsSegmentedView.setImage(.previous, forSegment: 0)
        self.controlsSegmentedView.setImage(.play, forSegment: 1)
        self.controlsSegmentedView.setImage(.next, forSegment: 2)
    }
    
    func prepareSongProgressSlider() {
        guard let cell = self.songProgressSlider.cell as? SliderCell else { return }
        
        cell.knobImage = .playhead
        cell.height    = 20
        cell.radius    = 0
        
        cell.backgroundColor = NSColor(patternImage: NSImage.playbar!)
        cell.highlightColor  = cell.backgroundColor
    }
    
    func prepareSongArtworkTitleButton() {
        self.songArtworkTitleButton.imagePosition = .imageLeading
    }
    
    func prepareSoundSlider() {
        let volume = helper.volume
        
        updateSoundPopoverButton(for: volume)
        
        // Set the player volume on the slider
        soundSlider.slider.integerValue = volume
    }

    func prepareShuffleRepeatSegmentedView() {
        // Set image for 'shuffle' button
        shuffleRepeatSegmentedView.setImage(.shuffling, forSegment: 0)
        
        // Set image for 'repeat' button
        shuffleRepeatSegmentedView.setImage(.repeating, forSegment: 1)
        
        updateShuffleRepeatSegmentedView()
    }
    
    // MARK: Notification handling
    
    var TrackChangedNotification: String {
        // Use 'type' because it's a static var
        return type(of: helper).TrackChangedNotification
    }
    
    func initNotificationWatcher() {
        // Attach the NotificationObserver for Spotify notifications
        DistributedNotificationCenter.default().addObserver(self,
                                       selector: #selector(hookNotification(notification:)),
                                       name: NSNotification.Name(rawValue: TrackChangedNotification),
                                       object: nil)
    }
    
    func deinitNotificationWatcher() {
        // Remove the NotificationObserver
        DistributedNotificationCenter.default().removeObserver(self,
                                          name: NSNotification.Name(rawValue: TrackChangedNotification),
                                          object: nil)
    }
    
    func isClosing(with notification: NSNotification) -> Bool {
        // This is only for Spotify!
        guard type(of: helper) == SpotifyHelper.self else { return false }
        
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
        if isClosing(with: notification) {
            handleClosing()
            return
        } else if shouldLoadSong {
            handleNewSong()
        } else {
            handlePlayPause()
        }
        
        trackSongProgress()
    }
    
    func resetSong() {
        // Set placeholder value
        // TODO: update artwork with some blank
        self.song = Song()
        
        // This avoids reopening while playing too
        deinitSongTrackingTimer()
        
        updateAfterNotification()
        
        // Reset song progress slider
        updateSongProgressSlider(with: 0)
    }
    
    func handleClosing() {
        resetSong()
    }
    
    func handleNewSong() {
        // New track notification
        willChangeValue(forKey: kSong)
        
        // Retrieve new value
        self.song = helper.song
        
        didChangeValue(forKey: kSong)
        
        updateAfterNotification()
    }
    
    func handlePlayPause() {
        // Play/pause notification
        updateControlsAfterPlayPause()
        
        // Update menuBar title
        updateMenuBar()
        
        // Set play/pause and update elapsed time on the TouchBar
        togglePlaybackState()
        updateNowPlayingInfoElapsedPlaybackTime(with: helper.playbackPosition)
    }
    
    var shouldLoadSong: Bool {
        // A new song should be fully reloaded only
        // if it's an actually different track
        return helper.song.name != self.song.name
    }
    
    // MARK: Playback progress handling
    
    func trackSongProgress() {
        if songTrackingTimer.isValid { deinitSongTrackingTimer() }
        
        if helper.isPlaying {
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
    
    func updateSongProgressSlider(with position: Double = -1) {
        if !isSliding {
            if !helper.doesSendPlayPauseNotification {
                // If the player does not send a play/pause notification
                // we must manually check if state has changed
                // This means the timer cannot be stopped though...
                // TODO: find a better way to do this
                if isUIPlaying != helper.isPlaying {
                    handlePlayPause()
                }
            }
            
            if helper.playbackPosition > self.song.duration && self.song.duration == 0 {
                // Hotfix for occasional song loading errors
                // TODO: Check if this is actually working
                self.song = helper.song
            }
            
            let position = position > -1 ? position : helper.playbackPosition
            
            songProgressSlider.doubleValue = position / self.song.duration
            
            // Also update native touchbar scrubber
            updateNowPlayingInfoElapsedPlaybackTime(with: position)
            
            // And the View's slider
            guard let viewController = self.contentViewController as? ViewController else { return }
            
            viewController.updateSongProgressSlider(with: position / self.song.duration)
        }
    }
    
    func syncSongProgressSlider() {
        guard helper.playerState != .stopped else {
            // Reset song data if player is stopped
            resetSong()
            return
        }
        
        // Convenience call for updating the progress slider during playback
        updateSongProgressSlider()
    }
    
    func updateControlsAfterPlayPause() {
        self.controlsSegmentedView.setImage(
            helper.isPlaying ? .pause : .play,
            forSegment: 1
        )
        
        if let viewController = self.contentViewController as? ViewController {
            viewController.updateButtons()
        }
    }
    
    func setShuffleRepeatSegmentedView(shuffleSelected: Bool?, repeatSelected: Bool?) {
        // Select 'shuffle' button
        if let shuffleSelected = shuffleSelected {
            shuffleRepeatSegmentedView.setSelected(shuffleSelected, forSegment: 0)
        }
        
        // Select 'repeat' button
        if let repeatSelected = repeatSelected {
            shuffleRepeatSegmentedView.setSelected(repeatSelected, forSegment: 1)
        }
    }
    
    func updateShuffleRepeatSegmentedView() {
        // Convenience call for updating the 'repeat' and 'shuffle' buttons
        setShuffleRepeatSegmentedView(shuffleSelected: helper.shuffling,
                                      repeatSelected: helper.repeating)
    }
    
    func updateSoundPopoverButton(for volume: Int) {
        // Change the popover icon based on current volume
        if (volume > 70) {
            soundPopoverButton.collapsedRepresentationImage = .volumeHigh
        } else if (volume > 30) {
            soundPopoverButton.collapsedRepresentationImage = .volumeMedium
        } else {
            soundPopoverButton.collapsedRepresentationImage = .volumeLow
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
    
    func updateAfterNotification(updateNowPlaying: Bool = true) {
        updateUIAfterNotification()
        
        if updateNowPlaying {
            // Also update TouchBar media controls
            updateNowPlayingInfo()
        }
        
        updateMenuBar()
    }
    
    func updateUIAfterNotification() {
        updateTouchBarUI()
        
        updateViewUI()
    }
    
    var shouldSetTitleOnMenuBar: Bool {
        // Determines wheter the title on the menuBar should be set
        return kShouldSetTitleOnMenuBar && self.song.isValid && helper.isPlaying
    }
    
    func updateMenuBar() {
        guard let delegate = self.delegate else { return }
        
        // Get the wrapped title
        let title = " " + self.song.name.truncate(at: kMenuItemMaximumLength)
        
        // Set the title on the menuBar if enabled
        delegate.menuItem.title = shouldSetTitleOnMenuBar ? title : nil
    }
    
    func updateTouchBarUI() {
        self.songArtworkTitleButton.title = self.song.name.truncate(at: 15)
        self.songArtworkTitleButton.sizeToFit()
        
        self.controlsSegmentedView.setImage(
            helper.isPlaying ? .pause : .play,
            forSegment: 1
        )
        
        // Also set image on VC's ImageView after download
        // Faster and more efficient
        guard let viewController = self.contentViewController as? ViewController else { return }
        
        if  let stringURL = helper.artwork() as? String,
            let artworkURL = URL(string: stringURL) {
            self.songArtworkTitleButton.loadImage(from: artworkURL, callback: { image in
                self.updateArtworkColorAndSize()
                
                viewController.updateFullSongArtworkView(with: image)
            })
        } else if let image = helper.artwork() as? NSImage {
            updateArtworkColorAndSize()
            
            viewController.updateFullSongArtworkView(with: image)
        }
    }
    
    func updateArtworkColorAndSize() {
        // Resize image to fit TouchBar view
        // TODO: Move this elsewhere
        self.songArtworkTitleButton.image = self.songArtworkTitleButton.image?.resized(to: NSMakeSize(30, 30))
        
        // Set bezel color
        // TODO: Share this colors with ViewController
        self.songArtworkTitleButton.image?.getColors(scaleDownSize: NSMakeSize(10, 10)) { colors in
            self.songArtworkTitleButton.bezelColor = colors.primary.blended(withFraction: 0.5, of: .darkGray)
        }
    }
    
    var isUIPlaying: Bool {
        // Simple trick to know whether the UI is in 'play' mode
        return self.controlsSegmentedView.image(forSegment: 1) == .pause
    }
    
    func updateViewUI() {
        guard let viewController = self.contentViewController as? ViewController else { return }
        
        viewController.updateTitleAlbumArtistView(for: self.song)
        
        viewController.updateButtons()
    }
    
}
