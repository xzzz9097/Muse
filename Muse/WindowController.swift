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

fileprivate extension NSTouchBarItemIdentifier {
    static let controlStripButton = NSTouchBarItemIdentifier(
        rawValue: "\(Bundle.main.bundleIdentifier!).TouchBarItem.controlStripButton"
    )
}

@available(OSX 10.12.2, *)
class WindowController: NSWindowController, NSWindowDelegate, SliderDelegate {
    
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
    // Constant for TouchBar slider bounds
    let xSliderBoundsThreshold: CGFloat = 25
    
    // iTunes notification fields
    // TODO: move this in a better place
    let iTunesNotificationTrackName          = "Name"
    let iTunesNotificationPlayerState        = "Player State"
    let iTunesNotificationPlayerStatePlaying = "Playing"

    // MARK: Outlets
    
    @IBOutlet weak var songArtworkTitleButton:     NSButton!
    @IBOutlet weak var songProgressSlider:         Slider!
    @IBOutlet weak var controlsSegmentedView:      NSSegmentedControl!
    @IBOutlet weak var likeButtonItem:             NSTouchBarItem!
    @IBOutlet weak var likeButton:                 NSButton!
    @IBOutlet weak var soundPopoverButton:         NSPopoverTouchBarItem!
    @IBOutlet weak var soundSlider:                NSSliderTouchBarItem!
    @IBOutlet weak var shuffleRepeatSegmentedView: NSSegmentedControl!
    @IBOutlet weak var soundPopoverTouchBar:       NSTouchBar!
    
    // MARK: Vars
    
    let controlStripItem = NSCustomTouchBarItem(identifier: .controlStripButton)
    
    weak var controlStripButton: NSButton? {
        set {
            controlStripItem.view = newValue!
        }
        get {
            return controlStripItem.view as? NSButton
        }
    }
    
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
    
    @IBAction func likeButtonClicked(_ sender: Any) {
        // Reverse like on current track if supported
        if helper.supportsLiking { helper.liked = !helper.liked }
    }
    
    // MARK: SliderDelegate implementation
    // Handles touch events from TouchBar song progres slider
    
    var wasPlaying = false
    
    /**
     Handles 'touchesBegan' events from the slider
     */
    func didTouchesBegan() {
        // Save player state
        wasPlaying = helper.isPlaying
        
        // Handle single touch events
        helper.scrub(to: songProgressSlider.doubleValue)
    }
    
    /**
     Handles 'touchesMoved' events from the slider
     */
    func didTouchesMoved() {
        // Pause player
        // so it doesn't mess with sliding
        if helper.isPlaying { helper.pause() }
        
        // Set new position to the player
        helper.scrub(to: songProgressSlider.doubleValue, touching: true)
    }
    
    /**
     Handles 'touchesEnded' events from the slider
     */
    func didTouchesEnd() {
        // Finalize and disable large knob
        helper.scrub(to: songProgressSlider.doubleValue)
        
        // Resume playing if needed
        if wasPlaying { helper.play() }
    }
    
    /**
     Handles 'touchesCancelled' events form the slider
     */
    func didTouchesCancel() {
        // Same action as touch ended
        didTouchesEnd()
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
        case kVK_ANSI_L:
            if helper.supportsLiking { helper.liked = !helper.liked }
        case kVK_ANSI_I:
            onViewController { controller in
                controller.showTitleView()
            }
        case kVK_ANSI_1:
            setPlayerHelper(to: .spotify)
            return
        case kVK_ANSI_2:
            setPlayerHelper(to: .itunes)
        case kVK_ANSI_3:
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
        // Set the new player
        helper = manager.get(id)
        
        // Register again the callbacks
        registerCallbacks()
        
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
            
            self.onViewController { controller in
                controller.showLastActionView(for: self.helper.isPlaying ? .play : .pause)
            }
        }
        
        // Callback for PlayerHelper's nextTrack() and previousTrack()
        helper.trackChangedHandler = { next in
            self.updateSongProgressSlider(with: 0)
            
            self.updateNowPlayingInfo()
            
            self.onViewController { controller in
                controller.showLastActionView(for: next ? .next : .previous)
                
                // Peek title of currently playing track
                controller.showTitleView()
            }
        }
        
        // Callback for PlayerHelper's goTo(Bool, Double?)
        helper.timeChangedHandler = { touching, doubleValue in
            guard let value = doubleValue else { return }
            
            let time = value * self.song.duration
            
            if let cell = self.songProgressSlider.cell as? SliderCell {
                // If we are sliding, show time near TouchBar slider knob
                cell.knobImage   = touching ? nil : .playhead
                cell.hasTimeInfo = touching
                cell.timeInfo    = time.secondsToMMSSString as NSString
            }
            
            self.updateSongProgressSlider(with: time)
            
            self.onViewController { controller in
                controller.showLastActionView(for: .scrubbing,
                                              to: time,
                                              shouldClose: !touching)
            }
            
            // Set 'isSliding' after a short delay
            // This prevents timer from resuming too early
            // after scrubbing, thus resetting the slider position
            DispatchQueue.main.run(after: 5) { self.isSliding = touching }
        }
        
        // Callback for PlayerHelper's shuffe/repeat setters
        helper.shuffleRepeatChangedHandler = { shuffleChanged, repeatChanged in
            // Update shuffleRepeat segmented view with new values
            self.updateShuffleRepeatSegmentedView()
            
            // Send shuffle/repeat action to VC
            self.onViewController { controller in
                if shuffleChanged {
                    controller.showLastActionView(for: .shuffling)
                } else if repeatChanged {
                    controller.showLastActionView(for: .repeating)
                }
            }
        }
        
        // Callback ofr PlayerHelper's like setter
        helper.likeChangedHandler = { likeChanged in
            // Update like button on TouchBar
            self.updateLikeButton()
            
            // Send like action to VC
            self.onViewController { controller in
                if likeChanged {
                    controller.showLastActionView(for: .like)
                }
            }
        }
        
        if let window = self.window, let delegate = self.delegate {
            // Callback for AppDelegate window toggled
            delegate.windowToggledHandler = { window.toggleVisibility() }
        }
    }
    
    // MARK: TouchBar injection
    
    /**
     Appends a system-wide button in NSTouchBar's control strip
     */
    @objc func injectControlStripButton() {
        prepareControlStripButton()
        
        DFRSystemModalShowsCloseBoxWhenFrontMost(true)
        
        controlStripItem.addToControlStrip()
    }
    
    func prepareControlStripButton() {
        controlStripButton = NSButton(title: "♫",
                                      target: self,
                                      action: #selector(presentModalTouchBar))
        
        controlStripButton?.imagePosition = .imageOverlaps
        controlStripButton?.isBordered    = false
        controlStripButton?.imageScaling  = .scaleNone
        
        controlStripButton?.addGestureRecognizer(controlStripButtonPressureGestureRecognizer)
        controlStripButton?.addGestureRecognizer(controlStripButtonPanGestureRecognizer)
    }
    
    func updateControlStripButton() {
        if song.isValid && helper.isPlaying {
            controlStripButton?.title = helper.playbackPosition.secondsToMMSSString
        } else {
            controlStripButton?.title = "♫"
        }
    }
    
    /**
     Recognizes long press gesture on the control strip button.
     We use this to toggle play/pause from the system bar.
     */
    var controlStripButtonPressureGestureRecognizer: NSPressGestureRecognizer {
        let recognizer = NSPressGestureRecognizer()
        
        recognizer.target = self
        recognizer.action = #selector(controlStripButtonPressureGestureHandler(_:))
        
        recognizer.minimumPressDuration = 0.25
        recognizer.allowedTouchTypes    = .direct  // Very important
        
        return recognizer
    }
    
    /**
     Recognizes pan (aka touch drag) gestures on the control strip button.
     We use this to jump to next/previous track.
     */
    var controlStripButtonPanGestureRecognizer: NSPanGestureRecognizer {
        let recognizer = NSPanGestureRecognizer()
        
        recognizer.target = self
        recognizer.action = #selector(controlStripButtonPanGestureHandler(_:))
        
        recognizer.allowedTouchTypes = .direct
        
        return recognizer
    }
    
    func controlStripButtonPressureGestureHandler(_ sender: NSGestureRecognizer?) {
        guard let recognizer = sender else { return }
        
        switch recognizer.state {
        case .began:
            // TODO: Add OSD notification
            helper.togglePlayPause()
        default:
            break
        }
    }
    
    func controlStripButtonPanGestureHandler(_ sender: NSGestureRecognizer?) {
        guard let recognizer = sender as? NSPanGestureRecognizer else { return }
        
        switch recognizer.state {
        case .began:
            // TODO: Add OSD notification
            // Reverse translation check (natural scroll)
            if recognizer.translation(in: controlStripButton).x < 0 {
                helper.nextTrack()
            } else {
                helper.previousTrack()
            }
        default:
            break
        }
    }
    
    /**
     Reveals the designated NSTouchBar when control strip button is pressed
     */
    func presentModalTouchBar() {
        NSTouchBar.presentSystemModalFunctionBar(
            touchBar,
            systemTrayItemIdentifier: NSTouchBarItemIdentifier.controlStripButton.rawValue)
    }
    
    // MARK: UI preparation
    
    override func windowDidLoad() {
        super.windowDidLoad()
        
        // Initialize AEManager for URL handling
        initEventManager()
        
        // Initialize notification watcher
        initNotificationWatchers()
        
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
        
        // Append system-wide button in Control Strip
        injectControlStripButton()
        
        // Update like button at cold start
        updateLikeButtonColdStart()
        
        soundPopoverButton.popoverTouchBar = soundPopoverTouchBar
    }
    
    func windowDidBecomeKey(_ notification: Notification) {
        // Try switching to another helper is song is blank
        // (that means previous player has been closed)
        // Or if helper is no longer available
        if song == Song() || !helper.isAvailable {
            setPlayerHelper(to: manager.designatedHelperID)
        }
        
        // Sync progress slider if song is not playing
        if !helper.isPlaying { syncSongProgressSlider() }
        
        // Sync the sound slider and button
        prepareSoundSlider()
        
        // Sync shuffling and repeating segmented control
        prepareShuffleRepeatSegmentedView()
        
        // Peek title of currently playing track
        self.onViewController { controller in
            controller.showTitleView()
        }
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
        song = helper.song
        
        updateAfterNotification()
        
        trackSongProgress()
    }
    
    func prepareButtons() {
        controlsSegmentedView.setImage(.previous, forSegment: 0)
        controlsSegmentedView.setImage(.play, forSegment: 1)
        controlsSegmentedView.setImage(.next, forSegment: 2)
    }
    
    func prepareSongProgressSlider() {
        songProgressSlider.delegate = self
        
        guard let cell = self.songProgressSlider.cell as? SliderCell else { return }
        
        cell.isTouchBar = true
    }
    
    func prepareSongArtworkTitleButton() {
        songArtworkTitleButton.imagePosition = .imageLeading
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
    
    // MARK: ViewController communication
    
    var viewController: ViewController? {
        return self.contentViewController as? ViewController
    }
    
    func onViewController(block: @escaping @convention(block) (ViewController) -> Swift.Void) {
        guard let controller = viewController else { return }
        
        // Pass controller to the block
        block(controller)
    }
    
    // MARK: URL events handling
    
    func initEventManager() {
        NSAppleEventManager.shared().setEventHandler(self,
                                                     andSelector: #selector(handleURLEvent),
                                                     forEventClass: AEEventClass(kInternetEventClass),
                                                     andEventID: AEEventID(kAEGetURL))
    }
    
    /**
     Catches URLs with specific prefix ("muse://")
     */
    func handleURLEvent(event: NSAppleEventDescriptor,
                        replyEvent: NSAppleEventDescriptor) {
        if  let urlDescriptor = event.paramDescriptor(forKeyword: keyDirectObject),
            let urlString     = urlDescriptor.stringValue,
            let urlComponents = URLComponents(string: urlString),
            let queryItems    = (urlComponents.queryItems as [NSURLQueryItem]?) {
            
            // Get "code=" parameter from URL
            // https://gist.github.com/gillesdemey/509bb8a1a8c576ea215a
            let code = queryItems.filter({ (item) in item.name == "code" }).first?.value!
            
            // Send code to SpotifyHelper -> Swiftify
            if let helper = helper as? SpotifyHelper, let authorizationCode = code {
                helper.saveToken(from: authorizationCode)
            }
        }
    }
    
    // MARK: Notification handling
    
    func initNotificationWatchers() {
        for (_, notification) in manager.TrackChangedNotifications {
            // Attach the NotificationObserver for Spotify notifications
            DistributedNotificationCenter.default().addObserver(self,
                                                                selector: #selector(hookNotification(notification:)),
                                                                name: notification,
                                                                object: nil)
        }
    }
    
    func deinitNotificationWatchers() {
        for (_, notification) in manager.TrackChangedNotifications {
            // Remove the NotificationObserver
            DistributedNotificationCenter.default().removeObserver(self,
                                                                   name: notification,
                                                                   object: nil)
        }
    }
    
    func isClosing(with notification: NSNotification) -> Bool {
        guard let userInfo = notification.userInfo else { return false }
        
        // This is only for Spotify and iTunes!
        if notification.name.rawValue == SpotifyHelper.rawTrackChangedNotification {
            // If the notification has only one item
            // that's the PlayerStateStopped -> player is closing
            return userInfo.count < 2
        } else if notification.name.rawValue == iTunesHelper.rawTrackChangedNotification {
            // For iTunes, since it sends a complete notification
            // we must check its content is somehow different from
            // last saved state (the one UI has)
            // TODO: find a way to make it work when closing from playing state
            guard   let name = userInfo[iTunesNotificationTrackName]    as? String,
                    let state = userInfo[iTunesNotificationPlayerState] as? String
            else { return userInfo.count < 2 }
            
            return  name == self.song.name &&
                    (state == iTunesNotificationPlayerStatePlaying) == isUIPlaying
        }
        
        return false
    }
    
    func hookNotification(notification: NSNotification) {
        // When Spotify is quitted, it sends an NSNotification
        // with only PlayerStateStopped, that causes it to
        // reopen for being polled by Muse
        // So we detect if the notification is a closing one
        guard !isClosing(with: notification) else {
            handleClosing()
            return
        }
        
        // Switch to a new helper
        // If the notification is sent from another player
        guard notification.name == helper.TrackChangedNotification else {
            setPlayerHelper(to: manager.designatedHelperID)
            return
        }
        
        if shouldLoadSong {
            handleNewSong()
        } else {
            handlePlayPause()
        }
        
        trackSongProgress()
    }
    
    func resetSong() {
        // Set placeholder value
        // TODO: update artwork with some blank
        song = Song()
        
        // This avoids reopening while playing too
        deinitSongTrackingTimer()
        
        // TODO: Disabled because was causing player to reopen
        //       Find a proper way to reset song data and update!
        // updateAfterNotification()
        
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
        song = helper.song
        
        didChangeValue(forKey: kSong)
        
        updateSongProgressSlider()
        
        updateAfterNotification()
    }
    
    func handlePlayPause() {
        // Play/pause notification
        updateControlsAfterPlayPause()
        
        // Update menuBar title
        updateMenuBar()
        
        // Set play/pause and update elapsed time on the TouchBar
        updatePlaybackState()
        updateNowPlayingInfoElapsedPlaybackTime(with: helper.playbackPosition)
    }
    
    var shouldLoadSong: Bool {
        // A new song should be fully reloaded only
        // if it's an actually different track
        return helper.song.name != song.name
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
        
        // Update control strip button title
        updateControlStripButton()
    }
    
    func deinitSongTrackingTimer() {
        // Invalidates the progress timer
        // e.g. when switching to a different song or on app close
        songTrackingTimer.invalidate()
    }
    
    func updateSongProgressSlider(with position: Double = -1) {
        if !helper.doesSendPlayPauseNotification {
            // If the player does not send a play/pause notification
            // we must manually check if state has changed
            // This means the timer cannot be stopped though...
            // TODO: find a better way to do this
            if isUIPlaying != helper.isPlaying {
                handlePlayPause()
            }
        }
        
        if helper.playbackPosition > song.duration && song.duration == 0 {
            // Hotfix for occasional song loading errors
            // TODO: Check if this is actually working
            song = helper.song
        }
        
        let position = position > -1 ? position : helper.playbackPosition
        
        songProgressSlider.doubleValue = position / song.duration
        
        controlStripButton?.title = position.secondsToMMSSString
        
        // Also update native touchbar scrubber
        updateNowPlayingInfoElapsedPlaybackTime(with: position)
        
        // And the View's slider
        onViewController { controller in
            controller.updateSongProgressSlider(with: position / self.song.duration)
        }
    }
    
    func syncSongProgressSlider() {
        guard helper.playerState != .stopped else {
            // Reset song data if player is stopped
            resetSong()
            return
        }
        
        // Convenience call for updating the progress slider during playback
        if !isSliding { updateSongProgressSlider() }
    }
    
    func updateControlsAfterPlayPause() {
        controlsSegmentedView.setImage(
            helper.isPlaying ? .pause : .play,
            forSegment: 1
        )
        
        onViewController { controller in
            controller.updateButtons()
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
    
    func updateLikeButton() {
        // Updates like button according to player support and track status
        if let helper = helper as? SpotifyHelper {
            likeButton.isEnabled = true
            
            // Spotify needs async saved loading from Web API 
            helper.isSaved { saved in
                self.likeButton.image = saved ? .liked : .like
            }
        } else if helper.supportsLiking {
            likeButton.isEnabled = true

            likeButton.image = helper.liked ? .liked : .like
        } else {
            likeButton.isEnabled = false
            
            likeButton.image = .liked
        }
    }
    
    func updateLikeButtonColdStart() {
        // Fetches the like status after time delay
        DispatchQueue.main.run(after: 200) {
            self.updateLikeButton()
        }
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
        deinitNotificationWatchers()
        
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
        return kShouldSetTitleOnMenuBar && song.isValid && helper.isPlaying
    }
    
    func updateMenuBar() {
        guard let delegate = self.delegate else { return }
        
        // Get the wrapped title
        let title = " " + song.name.truncate(at: kMenuItemMaximumLength)
        
        // Set the title on the menuBar if enabled
        delegate.menuItem.title = shouldSetTitleOnMenuBar ? title : nil
    }
    
    func updateTouchBarUI() {
        songArtworkTitleButton.title = song.name.truncate(at: 15)
        songArtworkTitleButton.sizeToFit()
        
        controlsSegmentedView.setImage(helper.isPlaying ? .pause : .play,
                                       forSegment: 1)
        
        if  let stringURL = helper.artwork() as? String,
            let artworkURL = URL(string: stringURL) {
            songArtworkTitleButton.loadImage(from: artworkURL, fallback: .defaultBg, callback: { image in
                self.updateArtworkColorAndSize(for: image)
                
                // Set image on ViewController when downloaded
                self.onViewController { controller in
                    controller.updateFullSongArtworkView(with: image)
                }
            })
        } else if let image = helper.artwork() as? NSImage {
            updateArtworkColorAndSize(for: image)
            
            onViewController { controller in
                controller.updateFullSongArtworkView(with: image)
            }
        } else if   let descriptor = helper.artwork() as? NSAppleEventDescriptor,
                    let image = NSImage(data: descriptor.data) {
            // Handles PNG artwork images
            updateArtworkColorAndSize(for: image)
            
            onViewController { controller in
                controller.updateFullSongArtworkView(with: image)
            }
        } else {
            let image = NSImage.defaultBg
            
            updateArtworkColorAndSize(for: image)
            
            onViewController { controller in
                controller.updateFullSongArtworkView(with: image)
            }
        }
        
        updateLikeButton()
    }
    
    func updateArtworkColorAndSize(for image: NSImage) {
        // Resize image to fit TouchBar view
        // TODO: Move this elsewhere
        songArtworkTitleButton.image = image.resized(to: NSMakeSize(30, 30))
        
        controlStripButton?.image = image.resized(
            to: NSMakeSize((controlStripButton?.frame.width)!,
                           (controlStripButton?.frame.width)!)
            ).withAlpha(0.5)
        
        
        // Fetch image colors
        // We also set an aggressive scaling size
        // to optimize performace and memory usage
        image.getColors(scaleDownSize: NSMakeSize(25, 25)) { colors in
            // Set colors on TouchBar button
            self.songArtworkTitleButton.bezelColor = colors.primary.blended(withFraction: 0.5, of: .darkGray)

            // Set colors on main view
            self.onViewController { controller in
                controller.colorViews(with: colors)
            }
        }
    }
    
    var isUIPlaying: Bool {
        // Simple trick to know whether the UI is in 'play' mode
        return controlsSegmentedView.image(forSegment: 1) == .pause
    }
    
    func updateViewUI() {
        onViewController { controller in
            controller.updateTitleAlbumArtistView(for: self.song)
            controller.updateButtons()
        }
    }
    
}
