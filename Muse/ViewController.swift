//
//  ViewController.swift
//  Muse
//
//  Created by Marco Albera on 21/11/16.
//  Copyright © 2016 Edge Apps. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {

    @IBOutlet weak var fullSongArtworkView: NSImageView!
    
    @IBOutlet weak var titleLabelView: NSTextField!
    @IBOutlet weak var albumArtistLabelView: NSTextField!
    
    var titleAlbumArtistSuperview: NSView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        titleAlbumArtistSuperview = titleLabelView.superview
        
        titleAlbumArtistSuperview.wantsLayer = true
    }
    
    override func viewWillAppear() {
        setBackgroundAndShadowForSuperView(titleAlbumArtistSuperview)
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
        layer.opacity = 0.95
        
        // Create shadow
        superview.shadow = NSShadow()
        layer.shadowColor = NSColor.shadowColor.cgColor
        layer.shadowRadius = 5.0
        layer.shadowOffset = NSMakeSize(0, -2.0)
        layer.shadowOpacity = 0.25
    }
    
    func updateFullSongArtworkViewForUrl(_ url: URL) {
        fullSongArtworkView.loadImageFromURL(url: url)
        
        fullSongArtworkView.imageScaling = .scaleAxesIndependently
    }
    
    func updateTitleAlbumArtistViewForSong(_ song: Song) {
        titleLabelView.stringValue = song.name
        
        albumArtistLabelView.stringValue = "\(song.artist) - \(song.album)"
    }
    
}

