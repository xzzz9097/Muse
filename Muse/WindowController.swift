//
//  WindowController.swift
//  Muse
//
//  Created by Marco Albera on 21/11/16.
//  Copyright © 2016 Edge Apps. All rights reserved.
//

import Cocoa

class WindowController: NSWindowController {
    var spotifyHelper = SpotifyHelper.sharedInstance
    
    var songTrackingTimer = Timer()
    
    var autoCloseTimer = Timer()
    var counter = 0
    
    var song = Song()
    let kSong = "song"

    override func windowDidLoad() {
        super.windowDidLoad()

        // Initialize our watcher
        initNotificationWatcher()
        
        // Set custom window attributes
        prepareWindow()
        
        if #available(OSX 10.12.1, *) {
            prepareButtons()
            prepareImageView()
        }
        
        // Register our DDHotKey
        registerHotkey()
        
        // Load song at cold start
        prepareSong()
    }

    // Outlets
    @IBOutlet weak var songArtworkView: NSImageView!
    @IBOutlet weak var songTitleLabel: NSTextField!
    @IBOutlet weak var songProgressSlider: NSSlider!
    
    @IBOutlet weak var controlsSegmentedView: NSSegmentedControl!
    
    var isSliding = false
    
    // Actions
    @IBAction func controlsSegmentedViewClicked(_ sender: Any) {
        guard let segmentedControl = sender as? NSSegmentedControl else { return }
        
        switch segmentedControl.selectedSegment {
        case 0:
            spotifyHelper.previousTrack()
            updateSongProgressSlider()
        case 1:
            spotifyHelper.togglePlayPause()
        case 2:
            spotifyHelper.nextTrack()
            updateSongProgressSlider()
        default:
            return
        }
    }
    
    @IBAction func progressSliderValueChanged(_ sender: Any) {
        if let slider = sender as? NSSlider {
            guard let currentEvent = NSApplication.shared().currentEvent else { return }
            
            for _ in (currentEvent.touches(matching: NSTouchPhase.began, in: slider)) {
                // Detected touch phase start
                isSliding = true
            }
            
            for _ in (currentEvent.touches(matching: NSTouchPhase.ended, in: slider)) {
                // Detected touch phase end
                isSliding = false
                
                spotifyHelper.goTo(time: slider.floatValue * self.song.duration)
            }
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
        window.collectionBehavior = .canJoinAllSpaces
        
        // Hide after losing focus
        window.hidesOnDeactivate = true
    }
    
    func prepareAutoClose() {
        // Timer for auto-close
        autoCloseTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: {
            timer in
            
            self.counter += 1
            
            if self.counter == 10 {
                timer.invalidate()
                
                self.counter = 0
            }
        })
    }
    
    func prepareSong() {
        self.song = spotifyHelper.songFromAppleScriptQuery()
        
        if #available(OSX 10.12.1, *) {
            updateUIAfterNotification()
        }
        
        trackSongProgress()
    }
    
    @available(OSX 10.12.1, *)
    func prepareButtons() {
        self.controlsSegmentedView.setImage(NSImage(named: NSImageNameTouchBarRewindTemplate), forSegment: 0)
        self.controlsSegmentedView.setImage(NSImage(named: NSImageNameTouchBarPlayPauseTemplate), forSegment: 1)
        self.controlsSegmentedView.setImage(NSImage(named: NSImageNameTouchBarFastForwardTemplate), forSegment: 2)
    }
    
    @available(OSX 10.12.1, *)
    func prepareImageView() {
        self.songArtworkView.wantsLayer = true
        self.songArtworkView.layer?.cornerRadius = 4.0
        self.songArtworkView.layer?.masksToBounds = true
    }
    
    func initNotificationWatcher() {
        // Attach the NotificationObserver for Spotify notifications
        DistributedNotificationCenter.default().addObserver(self, selector: #selector(hookNotification(notification:)), name: NSNotification.Name(rawValue: spotifyNotificationID), object: nil)
    }
    
    func hookNotification(notification: NSNotification) {
        willChangeValue(forKey: kSong)
        
        // Retrieve new value from notification
        self.song = spotifyHelper.songFromAppleScriptQuery()
        
        didChangeValue(forKey: kSong)
        
        if #available(OSX 10.12.1, *) {
            updateUIAfterNotification()
        }
        
        trackSongProgress()
    }
    
    func registerHotkey() {
        let modifiers: UInt = NSEventModifierFlags.control.rawValue | NSEventModifierFlags.command.rawValue
        
        DDHotKeyCenter.shared().registerHotKey(withKeyCode: 1, modifierFlags: modifiers, target: self, action: #selector(hotkeyAction), object: nil)
    }
    
    func hotkeyAction() {
        guard let window = self.window else { return }
        
        if (window.isKeyWindow) {
            // Hide window if focused
            window.orderOut(self)
            
            NSApp.hide(self)
        } else {
            // Show window if not
            window.makeKeyAndOrderFront(self)
            
            NSApp.activate(ignoringOtherApps: true)
        }
    }
    
    func trackSongProgress() {
        if song.isPlaying {
            songTrackingTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(updateSongProgressSlider), userInfo: nil, repeats: true)
        } else {
            songTrackingTimer.invalidate()
            updateSongProgressSlider()
        }
    }
    
    func updateSongProgressSlider() {
        if (!isSliding) {
            guard let currentPlaybackPosition = spotifyHelper.currentPlaybackPosition() else { return }
            
            self.song.playbackPosition = currentPlaybackPosition
            songProgressSlider.floatValue = self.song.playbackPosition / self.song.duration
        }
    }
    
    @available(OSX 10.12.1, *)
    func updateUIAfterNotification() {
        self.songTitleLabel.stringValue = self.song.name
        
        self.controlsSegmentedView.setImage(
            self.song.isPlaying ?
            NSImage(named: NSImageNameTouchBarPauseTemplate) :
            NSImage(named: NSImageNameTouchBarPlayTemplate),
            forSegment: 1
        )
        
        if let artworkURL = URL(string: self.song.artworkURL) {
            self.songArtworkView.loadImageFromURL(url: artworkURL)
            
            if let viewController = self.contentViewController as? ViewController {
                // Also update cover art in ViewController
                viewController.fullSongArtworkView.loadImageFromURL(url: artworkURL)
                viewController.fullSongArtworkView.imageScaling = .scaleAxesIndependently
            }
        }
    }
    
}
