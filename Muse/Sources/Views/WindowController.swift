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
fileprivate extension NSTouchBarItem.Identifier {
    static let controlStripButton = NSTouchBarItem.Identifier(
        rawValue: "\(Bundle.main.bundleIdentifier!).TouchBarItem.controlStripButton"
    )
}

@available(OSX 10.12.2, *)
class WindowController: NSWindowController, NSWindowDelegate, SliderDelegate {
    
    // MARK: App delegate getter
    
    let delegate = NSApplication.shared.delegate as? AppDelegate
    
    // MARK: Helpers

    let manager: PlayersManager = PlayersManager.shared
    var helper: PlayerHelper    = PlayersManager.shared.designatedHelper
    let nowPlayingInfoCenter    = MPNowPlayingInfoCenter.default()
    let remoteCommandCenter     = MPRemoteCommandCenter.shared()
    
    // MARK: Key monitor
    var eventMonitor: Any?
    
    // MARK: Runtime properties
    
    var song                           = Song()
    var nowPlayingInfo: [String : Any] = [:]
    var autoCloseTimeout: TimeInterval = 1.5
    
    // MARK: Timers
    
    var songTrackingTimer = Timer()
    var autoCloseTimer    = Timer()
    
    // MARK: Keys
    
    let kSong = "song"
    // Constant for setting menu title length
    let kMenuItemMaximumLength = 20
    // Constant for setting song title maximum length in TouchBar button
    let songTitleMaximumLength = 14
    // Constant for TouchBar slider bounds
    let xSliderBoundsThreshold: CGFloat = 25
    
    // iTunes notification fields
    // TODO: move this in a better place
    let iTunesNotificationTrackName          = "Name"
    let iTunesNotificationPlayerState        = "Player State"
    let iTunesNotificationPlayerStatePlaying = "Playing"

    // MARK: Outlets
    
    weak var songArtworkTitleButton:     NSCustomizableButton?
    weak var songProgressSlider:         Slider?
    weak var controlsSegmentedView:      NSSegmentedControl?
    weak var likeButton:                 NSButton?
    weak var soundPopoverButton:         NSPopoverTouchBarItem?
    weak var soundSlider:                NSSliderTouchBarItem?
    weak var shuffleRepeatSegmentedView: NSSegmentedControl?
    
    // MARK: Preferences
    
    // Show control strip item
    var shouldShowControlStripItem: Bool {
        set {
            if let window = window, !window.isKeyWindow {
                toggleControlStripButton(force: true, visible: newValue)
            }
        }
        
        get {            
            return Preference<Bool>(.controlStripItem).value
        }
    }
    
    // Show OSD on control strip button action
    var shouldShowHUDForControlStripAction: Bool {
        get {
            return Preference<Bool>(.controlStripHUD).value
        }
    }
    
    // Constant for enabling title on menuBar
    var shouldSetTitleOnMenuBar: Bool {
        set {
            updateMenuBar()
        }
        
        get {
            // Determines wheter the title on the menuBar should be set
            return  Preference<Bool>(.menuBarTitle).value &&
                    song.isValid &&
                    helper.isPlaying
        }
    }
    
    // MARK: Vars
    
    let controlStripItem = NSControlStripTouchBarItem(identifier: .controlStripButton)
    
    var controlStripButton: NSCustomizableButton? {
        set {
            controlStripItem.view = newValue!
        }
        get {
            return controlStripItem.view as? NSCustomizableButton
        }
    }
    
    // Hardcoded control strip item size
    // frame.size returns a wrong value at cold start
    let controlStripButtonSize = NSMakeSize(58.0, 58.0)
    
    var didPresentAsSystemModal = false
    
    var isSliding = false
    
    // Returns whether the UI is in play state
    var isUIPlaying = false
    
    // If an event is sent from TouchBar control strip button should not be refreshed
    // Set to true at event sent, reset to false after notification is received
    var eventSentFromApp = false
    
    // MARK: Actions
    
    @objc func controlsSegmentedViewClicked(_ sender: NSSegmentedControl) {
        switch sender.selectedSegment {
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
    
    @objc func shuffleRepeatSegmentedViewClicked(_ sender: NSSegmentedControl) {
        let selectedSegment = sender.selectedSegment
        
        switch selectedSegment {
        case 0:
            // Toggle shuffling
            shuffleButtonClicked(sender)
        case 1:
            // Toggle repeating
            repeatButtonClicked(sender)
        default:
            return
        }
    }
    
    @objc func shuffleButtonClicked(_ sender: Any) {
        switch sender {
        case let segmented as NSSegmentedControl:
            helper.shuffling = segmented.isSelected(forSegment: segmented.selectedSegment)
        case _ as NSButton:
            helper.shuffling = !helper.shuffling
        default:
            break
        }
    }
    
    @objc func repeatButtonClicked(_ sender: Any) {
        switch sender {
        case let segmented as NSSegmentedControl:
            helper.repeating = segmented.isSelected(forSegment: segmented.selectedSegment)
        case _ as NSButton:
            helper.repeating = !helper.repeating
        default:
            break
        }
    }
    
    @IBAction func soundSliderValueChanged(_ sender: NSSliderTouchBarItem) {
        // Set the volume on the player
        helper.volume = sender.slider.integerValue
        
        updateSoundPopoverButton(for: helper.volume)
    }
    
    func songArtworkTitleButtonClicked(_ sender: NSButton) {
        // Jump to player when the artwork on the TouchBar is tapped
        showPlayer()
    }
    
    func likeButtonClicked(_ sender: NSButton) {
        // Reverse like on current track if supported
        if var helper = helper as? LikablePlayerHelper {
            helper.toggleLiked()
        }
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
        helper.scrub(to: songProgressSlider?.doubleValue, touching: false)
    }
    
    /**
     Handles 'touchesMoved' events from the slider
     */
    func didTouchesMoved() {
        // Pause player
        // so it doesn't mess with sliding
        if helper.isPlaying { helper.pause() }
        
        // Set new position to the player
        helper.scrub(to: songProgressSlider?.doubleValue, touching: true)
    }
    
    /**
     Handles 'touchesEnded' events from the slider
     */
    func didTouchesEnd() {
        // Finalize and disable large knob
        helper.scrub(to: songProgressSlider?.doubleValue, touching: false)
        
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
    
    func initKeyDownHandler() {
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: NSEvent.EventTypeMask.keyDown,
            handler: { event in
                if self.handleKeyDown(with: event) { return nil }
                
                return event
        })
    }
    
    func deinitKeyDownHandler() {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }
    
    @discardableResult
    func handleKeyDown(with event: NSEvent) -> Bool {
        // Ensure that no text field is first responder
        // We don't want to intercept keystrokes while text editing
        if let _ = window?.firstResponder as? NSTextView { return false }
        
        switch KeyCombination(event.modifierFlags, event.keyCode) {
        case KeyCombination(.command, kVK_ANSI_S):
            setPlayerHelper(to: .spotify)
            return true
        case KeyCombination(.command, kVK_ANSI_I):
            setPlayerHelper(to: .itunes)
            return true
        case KeyCombination(.command, kVK_ANSI_V):
            setPlayerHelper(to: .vox)
            return true
        case kVK_Escape:
            onViewController {
                if !$0.handleEscape() {
                    if let window = self.window { window.setVisibility(false) }
                }
            }
            return true
        case kVK_LeftArrow, kVK_ANSI_A:
            helper.previousTrack()
            return true
        case kVK_Space, kVK_ANSI_S:
            helper.togglePlayPause()
            return true
        case kVK_RightArrow, kVK_ANSI_D:
            helper.nextTrack()
            return true
        case kVK_UpArrow, kVK_DownArrow:
            onViewController { $0.handleArrowKeysOrReturn() }
            return true
        case kVK_Return:
            onViewController { [weak self] in
                if !$0.handleArrowKeysOrReturn() {
                    self?.showPlayer()
                }
            }
        case kVK_ANSI_W:
            showPlayer()
            return true
        case kVK_ANSI_X:
            helper.toggleShuffling()
            return true
        case kVK_ANSI_R:
            helper.toggleRepeating()
            return true
        case kVK_ANSI_L:
            if var helper = helper as? LikablePlayerHelper { helper.toggleLiked() }
        default:
            break
        }
        
        return false
    }
    
    func registerHotkey() {
        guard let hotkeyCenter = DDHotKeyCenter.shared() else { return }
        
        let modifiers: UInt = NSEvent.ModifierFlags.control.rawValue | NSEvent.ModifierFlags.command.rawValue
        
        // Register system-wide summon hotkey
        hotkeyCenter.registerHotKey(withKeyCode: UInt16(kVK_ANSI_S),
                                    modifierFlags: modifiers,
                                    target: self,
                                    action: #selector(hotkeyAction),
                                    object: nil)
    }
    
    func hotkeyAction() {
        if let window = self.window {
            if didPresentAsSystemModal {
                // Dismiss system modal bar before opening the window
                // touch bar gets broken otherwise
                touchBar?.minimizeSystemModal()
            }
            
            window.toggleVisibility()
        }
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
    
    /**
     Callback for PlayerHelper's togglePlayPause()
     */
    func playPauseHandler() {
        if !helper.doesSendPlayPauseNotification {
            handlePlayPause()
            trackSongProgress()
        }
    }
    
    /**
     Callback for PlayerHelper's nextTrack() and previousTrack()
     */
    func trackChangedHandler(next: Bool) {
        updateSongProgressSlider(with: 0)
        
        updateNowPlayingInfo()
    }
    
    /**
     Callback for PlayerHelper's goTo(Bool, Double?)
     */
    func timeChangedHandler(touching: Bool, time: Double) {
        if let cell = songProgressSlider?.cell as? SliderCell {
            // If we are sliding, show time near TouchBar slider knob
            cell.knobImage   = touching ? nil : .playhead
            cell.hasTimeInfo = touching
            cell.timeInfo    = time.secondsToMMSSString as NSString
        }
        
        updateSongProgressSlider(with: time)
        
        // Set 'isSliding' after a short delay
        // This prevents timer from resuming too early
        // after scrubbing, thus resetting the slider position
        DispatchQueue.main.run(after: 5) { self.isSliding = touching }
    }
    
    func registerCallbacks() {
        PlayerNotification.observe { [weak self] event in
            guard let strongSelf = self else { return }
            
            strongSelf.eventSentFromApp = true
            
            switch event {
            case .play, .pause:
                strongSelf.playPauseHandler()
            case .next:
                strongSelf.trackChangedHandler(next: true)
            case .previous:
                strongSelf.trackChangedHandler(next: false)
            case .scrub(let touching, let time):
                strongSelf.timeChangedHandler(touching: touching, time: time)
            case .shuffling(let enabled):
                strongSelf.setShuffleRepeatSegmentedView(shuffleSelected: enabled)
            case .repeating(let enabled):
                strongSelf.setShuffleRepeatSegmentedView(repeatSelected: enabled)
            case .like(let liked):
                // Update like button on TouchBar
                strongSelf.updateLikeButton(newValue: liked)
            }
            
            // Reset event sent variable for events that don't send a notification
            switch event {
            case .scrub(_, _), .shuffling(_), .repeating(_), .like(_):
                strongSelf.eventSentFromApp = false
            default: break
            }
        }
        
        PreferenceNotification<Bool>.observe { [weak self] event in
            guard let strongSelf = self else { return }
            
            switch event.key {
            case .controlStripItem:
                strongSelf.shouldShowControlStripItem = event.value
            case .menuBarTitle:
                strongSelf.shouldSetTitleOnMenuBar = event.value
            default: break
            }
        }
    }
    
    // MARK: TouchBar injection
    
    /**
     Appends a system-wide button in NSTouchBar's control strip
     */
    @objc func injectControlStripButton() {
        prepareControlStripButton()
        
        DFRSystemModalShowsCloseBoxWhenFrontMost(true)
        
        if shouldShowControlStripItem {
            controlStripItem.isPresentInControlStrip = true
        }
    }
    
    func prepareControlStripButton() {
        controlStripButton = NSCustomizableButton(
            title: "11:11",
            target: self,
            action: #selector(presentModalTouchBar),
            hasRoundedLeadingImage: false
        )
        
        controlStripButton?.textColor     = NSColor.white.withAlphaComponent(0.8)
        controlStripButton?.font          = NSFont.monospacedDigitSystemFont(ofSize: 16.0,
                                                                             weight: NSFont.Weight.regular)
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
            helper.togglePlayPause()
            
            if shouldShowHUDForControlStripAction {
                window?.isVisibleAsHUD = true
                startAutoClose()
            }
        default:
            break
        }
    }
    
    func controlStripButtonPanGestureHandler(_ sender: NSGestureRecognizer?) {
        guard let recognizer = sender as? NSPanGestureRecognizer else { return }
        
        switch recognizer.state {
        case .began:
            // Reverse translation check (natural scroll)
            if recognizer.translation(in: controlStripButton).x < 0 {
                helper.nextTrack()
            } else {
                helper.previousTrack()
            }
            
            if shouldShowHUDForControlStripAction {
                DispatchQueue.main.run(after: 100) {
                    self.window?.isVisibleAsHUD = true
                    self.startAutoClose()
                }
            }
        default:
            break
        }
    }
    
    /**
     Reveals the designated NSTouchBar when control strip button @objc is pressed
     */
    @objc func presentModalTouchBar() {
        updatePopoverButtonForControlStrip()
        
        touchBar?.presentAsSystemModal(for: controlStripItem)
        
        didPresentAsSystemModal = true
    }
    
    // MARK: UI preparation
    
    override func windowDidLoad() {
        super.windowDidLoad()
        
        // Initialize AEManager for URL handling
        initEventManager()
        
        // Initialize event monitor for keyDown
        initKeyDownHandler()
        
        // Initialize notification watcher
        initNotificationWatchers()
        
        // Set custom window attributes
        prepareWindow()
        
        // Register callbacks for PlayerHelper
        registerCallbacks()
        
        // Register our DDHotKey
        registerHotkey()
        
        // Prepare system-wide controls
        prepareRemoteCommandCenter()
        
        // Append system-wide button in Control Strip
        injectControlStripButton()
        
        // Show window
        window?.setVisibility(true)
    }
    
    func windowDidBecomeKey(_ notification: Notification) {
        // Try switching to another helper is song is blank
        // (that means previous player has been closed)
        // Or if helper is no longer available
        // Also this loads song at cold start
        if song == Song() || !helper.isAvailable {
            setPlayerHelper(to: manager.designatedHelperID)
        }
        
        // Sync progress slider if song is not playing
        if !helper.isPlaying { syncSongProgressSlider() }
        
        // Sync the sound slider and button
        prepareSoundSlider()
        
        // Sync shuffling and repeating segmented control
        prepareShuffleRepeatSegmentedView()
        
        // Update control strip button title
        updateControlStripButton()
        
        // Peek title of currently playing track
        self.onViewController { controller in
            controller.showTitleView()
        }
        
        toggleControlStripButton(visible: false)
        
        // Invalidate TouchBar to make it reload
        // This ensures it's always correctly displayed
        // Only if system modal bar has been used
        if didPresentAsSystemModal {
            touchBar                = nil
            didPresentAsSystemModal = false
        }
        
        // Update like button when window becomes key
        updateLikeButtonColdStart()
    }
    
    func windowDidResignKey(_ notification: Notification) {
        // Make sure we reset sent event variable
        eventSentFromApp = false
        
        toggleControlStripButton(visible: true)
        
        // End search in VC
        onViewController {
            // TODO: implement this in some other way
            $0.endSearch(canceled: true)
        }
    }
    
    func toggleControlStripButton(force: Bool = false, visible: Bool = false) {
        let shouldShow = force ? visible : (visible && shouldShowControlStripItem)
        
        controlStripButton?.animator().isHidden  = !shouldShow
        controlStripItem.isPresentInControlStrip = shouldShow
    }
    
    func prepareWindow() {
        guard let window = self.window else { return }
        
        window.titleVisibility = NSWindow.TitleVisibility.hidden;
        window.titlebarAppearsTransparent = true
        window.styleMask.update(with: NSWindow.StyleMask.fullSizeContentView)
        
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
    
    func startAutoClose() {
        // Ensures any existing auto-close timer is cancelled
        autoCloseTimer.invalidate()
        
        // Timer for auto-close
        autoCloseTimer = Timer.scheduledTimer(withTimeInterval: autoCloseTimeout,
                                              repeats: false) { timer in
            timer.invalidate()
            
            // Reset count and close the window
            self.window?.isVisibleAsHUD = false
        }
    }
    
    func prepareSong() {
        song = helper.song
        
        updateAfterNotification()
        
        trackSongProgress()
    }
    
    func prepareButtons() {
        controlsSegmentedView?.target       = self
        controlsSegmentedView?.segmentCount = 3
        controlsSegmentedView?.segmentStyle = .separated
        controlsSegmentedView?.trackingMode = .momentary
        controlsSegmentedView?.action       = #selector(controlsSegmentedViewClicked(_:))
        
        controlsSegmentedView?.setImage(.previous, forSegment: 0)
        controlsSegmentedView?.setImage(.play, forSegment: 1)
        controlsSegmentedView?.setImage(.next, forSegment: 2)
        
        (0..<(controlsSegmentedView?.segmentCount)!).forEach {
            controlsSegmentedView?.setWidth(45.0, forSegment: $0)
        }
    }
    
    func prepareSongProgressSlider() {
        songProgressSlider?.delegate = self
        songProgressSlider?.minValue = 0.0
        songProgressSlider?.maxValue = 1.0
        
        if songProgressSlider?.doubleValue == 0.0 {
            songProgressSlider?.doubleValue = helper.playbackPosition / song.duration
        }
    }
    
    func prepareSongArtworkTitleButton() {
        songArtworkTitleButton?.target        = self
        songArtworkTitleButton?.bezelStyle    = .rounded
        songArtworkTitleButton?.alignment     = .center
        songArtworkTitleButton?.fontSize      = 16.0
        songArtworkTitleButton?.imagePosition = .imageLeading
        songArtworkTitleButton?.action        = #selector(songArtworkTitleButtonClicked(_:))
        
        songArtworkTitleButton?.hasRoundedLeadingImage = true
        
        songArtworkTitleButton?.addGestureRecognizer(songArtworkTitleButtonPanGestureRecognizer)
    }
    
    /**
     Recognizes pan (aka touch drag) gestures on the song artwork+title button.
     We use this to toggle song information on the button
     */
    var songArtworkTitleButtonPanGestureRecognizer: NSGestureRecognizer {
        let recognizer = NSPanGestureRecognizer()
        
        recognizer.target = self
        recognizer.action = #selector(songArtworkTitleButtonPanGestureHandler(_:))
        
        recognizer.allowedTouchTypes = .direct
        
        return recognizer
    }
    
    func songArtworkTitleButtonPanGestureHandler(_ recognizer: NSPanGestureRecognizer) {
        if case .began = recognizer.state {
            songArtworkTitleButton?.title =
                recognizer.translation(in: songArtworkTitleButton).x > 0 ?
                song.name.truncate(at: songTitleMaximumLength)           :
                song.artist.truncate(at: songTitleMaximumLength)
        }
    }
    
    func prepareSoundSlider() {
        soundSlider?.target          = self
        soundSlider?.slider.minValue = 0.0
        soundSlider?.slider.maxValue = 100.0
        soundSlider?.action          = #selector(soundSliderValueChanged(_:))
        
        soundSlider?.minimumValueAccessory = NSSliderAccessory(image: NSImage.volumeLow!)
        soundSlider?.maximumValueAccessory = NSSliderAccessory(image: NSImage.volumeHigh!)
        soundSlider?.valueAccessoryWidth   = .wide
        
        // Set the player volume on the slider
        soundSlider?.slider.integerValue = helper.volume
    }

    func prepareShuffleRepeatSegmentedView() {
        shuffleRepeatSegmentedView?.target       = self
        shuffleRepeatSegmentedView?.segmentCount = 2
        shuffleRepeatSegmentedView?.segmentStyle = .separated
        shuffleRepeatSegmentedView?.trackingMode = .selectAny
        shuffleRepeatSegmentedView?.action       = #selector(shuffleRepeatSegmentedViewClicked(_:))
        
        // Set image for 'shuffle' button
        shuffleRepeatSegmentedView?.setImage(.shuffling, forSegment: 0)
        
        // Set image for 'repeat' button
        shuffleRepeatSegmentedView?.setImage(.repeating, forSegment: 1)
        
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
     Catches URLs with specific prefix (@objc "muse://")
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
        // Set up player and system wake event watchers
        initPlayerNotificationWatchers()
        initWakeNotificationWatcher()
    }
    
    func initWakeNotificationWatcher() {
        // Attach the NotificationObserver for system wake notification
        NSWorkspace.shared().notificationCenter.addObserver(forName: .NSWorkspaceDidWake,
                                                            object: nil,
                                                            queue: nil,
                                                            using: hookWakeNotification)
    }
    
    func hookWakeNotification(notification: Notification) {
        // Reset and reload touchBar when system wakes up
        touchBar                = nil
        didPresentAsSystemModal = false
        
        // Update control strip button visibility
        toggleControlStripButton(visible: true)
    }
    
    func initPlayerNotificationWatchers() {
        for (_, notification) in manager.TrackChangedNotifications {
            // Attach the NotificationObserver for Spotify notifications
            DistributedNotificationCenter.default().addObserver(forName: notification,
                                                                object: nil,
                                                                queue: nil,
                                                                using: hookPlayerNotification)
        }
    }
    
    func deinitPlayerNotificationWatchers() {
        for (_, notification) in manager.TrackChangedNotifications {
            // Remove the NotificationObserver
            DistributedNotificationCenter.default().removeObserver(self,
                                                                   name: notification,
                                                                   object: nil)
        }
    }
    
    func isClosing(with notification: Notification) -> Bool {
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
    
    func hookPlayerNotification(notification: Notification) {
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
        
        // If window is not key, restore control strip button visibility
        // TODO: add a preference for this
        // TODO: improve control on when the button should be refreshed
        if let key = window?.isKeyWindow, !key, !eventSentFromApp {
            toggleControlStripButton(visible: true)
        }
        
        // Reset event sending check
        eventSentFromApp = false
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
            
            // Set timer tolerance
            // Improves performance by giving the system more headroom
            // for polling frequency. 
            songTrackingTimer.tolerance = 0.1
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
        
        songProgressSlider?.doubleValue = position / song.duration
        
        if isUIPlaying {
            controlStripButton?.title = position.secondsToMMSSString
        }
        
        // Also update native touchbar scrubber
        updateNowPlayingInfoElapsedPlaybackTime(with: position)
        
        // And the View's slider
        onViewController { controller in
            controller.updateSongProgressSlider(with: position / self.song.duration)
            @objc       }
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
        isUIPlaying = helper.isPlaying
        
        controlsSegmentedView?.setImage(isUIPlaying ? .pause : .play,
                                        forSegment: 1)
        
        onViewController { controller in
            controller.updateButtons()
        }
    }
    
    func setShuffleRepeatSegmentedView(shuffleSelected: Bool? = nil, repeatSelected: Bool? = nil) {
        // Select 'shuffle' button
        if let shuffleSelected = shuffleSelected {
            shuffleRepeatSegmentedView?.setSelected(shuffleSelected, forSegment: 0)
        }
        
        // Select 'repeat' button
        if let repeatSelected = repeatSelected {
            shuffleRepeatSegmentedView?.setSelected(repeatSelected, forSegment: 1)
        }
    }
    
    func updateShuffleRepeatSegmentedView() {
        // Convenience call for updating the 'repeat' and 'shuffle' buttons
        setShuffleRepeatSegmentedView(shuffleSelected: helper.shuffling,
                                      repeatSelected: helper.repeating)
        
        onViewController { [weak self] controller in
            controller.updateShuffleRepeatButtons(shuffling: self?.helper.shuffling,
                                                  repeating: self?.helper.repeating)
        }
    }
    
    func updateLikeButton(newValue: Bool? = nil) {
        if let liked = newValue {
            setLikeButton(value: liked)
            return
        }
        
        // Updates like button according to player support and track status
        if let helper = helper as? SpotifyHelper {
            likeButton?.isEnabled = true
            
            // Spotify needs async saved loading from Web API 
            helper.isSaved { saved in
                self.setLikeButton(value: saved)
            }
        } else if let helper = helper as? LikablePlayerHelper {
            likeButton?.isEnabled = true

            setLikeButton(value: helper.liked)
        } else {
            likeButton?.isEnabled = false
            
            setLikeButton(value: true)
        }
    }
    
    func setLikeButton(value: Bool) {
        likeButton?.image = value ? .liked : .like
        
        // Update VC's like button
        self.onViewController { controller in
            controller.updateLikeButton(liked: value)
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
            soundPopoverButton?.collapsedRepresentationImage = .volumeHigh
        } else if (volume > 30) {
            soundPopoverButton?.collapsedRepresentationImage = .volumeMedium
        } else {
            soundPopoverButton?.collapsedRepresentationImage = .volumeLow
        }
    }
    
    // MARK: Deinitialization
    
    func windowWillClose(_ notification: Notification) {
        // Remove the observer when window is closed
        deinitPlayerNotificationWatchers()
        
        // Remove the keyDown event monitor
        deinitKeyDownHandler()
        
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
        isUIPlaying = helper.isPlaying
        
        updateTouchBarUI()
        
        updateViewUI()
    }
    
    func updateMenuBar() {
        guard let delegate = self.delegate else { return }
        
        // Get the wrapped title
        let title = "♫ " + song.name.truncate(at: kMenuItemMaximumLength)
        
        // Set the title on the menuBar if enabled
        delegate.menuItem.title = shouldSetTitleOnMenuBar ? title : "♫"
    }
    
    var image: NSImage = .defaultBg {
        didSet {
            self.updateArtworkColorAndSize(for: image)
            
            // Set image on ViewController when downloaded
            self.onViewController { controller in
                controller.updateFullSongArtworkView(with: self.image)
            }
        }
    }
    
    func fetchArtwork() {
        if  let stringURL = helper.artwork() as? String,
            let artworkURL = URL(string: stringURL) {
            NSImage.download(from: artworkURL,
                             fallback: .defaultBg) { self.image = $0 }
        } else if let image = helper.artwork() as? NSImage {
            self.image = image
        } else if   let descriptor = helper.artwork() as? NSAppleEventDescriptor,
            let image = NSImage(data: descriptor.data) {
            // Handles PNG artwork images
            self.image = image
        } else if song.isValid {
            // If we have song info but no cover
            // we try fetching the image from Spotify servers
            // providing title and artist name
            // TODO: more testing!
            SpotifyHelper.shared.fetchTrackInfo(title: self.song.name,
                                                artist: self.song.artist)
            { track in
                guard let album = track.album else { return }
                
                NSImage.download(from: URL(string: album.artUri)!,
                                 fallback: .defaultBg) { self.image = $0 }
            }
        } else {
            self.image = NSImage.defaultBg
        }
    }
    
    func updateTouchBarUI() {
        songArtworkTitleButton?.title = song.name.truncate(at: songTitleMaximumLength)
        songArtworkTitleButton?.sizeToFit()
        
        controlsSegmentedView?.setImage(helper.isPlaying ? .pause : .play,
                                       forSegment: 1)
        
        fetchArtwork()
 
        updateLikeButton()
    }
    
    func updateArtworkColorAndSize(for image: NSImage) {
        // Resize image to fit TouchBar view
        // TODO: Move this elsewhere
        songArtworkTitleButton?.image = image.resized(to: NSMakeSize(30, 30))
        
        if image != .defaultBg {
            controlStripButton?.image = image.resized(to: controlStripButtonSize)
                                             .withAlpha(0.3)
        } else {
            controlStripButton?.image = nil
        }
        
        
        // Fetch image colors
        // We also set an aggressive scaling size
        // to optimize performace and memory usage
        image.getColors(scaleDownSize: NSMakeSize(25, 25)) { colors in
            // Set colors on TouchBar button
            self.songArtworkTitleButton?.bezelColor = colors.primary.blended(withFraction: 0.5, of: .darkGray)

            // Set colors on main view
            self.onViewController { controller in
                controller.colorViews(with: colors)
            }
        }
    }
    
    func updateViewUI() {
        onViewController { controller in
            controller.updateTitleAlbumArtistView(for: self.song)
            controller.updateButtons()
        }
    }
    
}
