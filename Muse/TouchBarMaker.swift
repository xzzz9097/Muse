//
//  TouchBarMaker.swift
//  Muse
//
//  Created by Marco Albera on 18/07/2017.
//  Copyright © 2017 Edge Apps. All rights reserved.
//

import Cocoa

fileprivate extension NSTouchBarCustomizationIdentifier {
    static let windowBar = NSTouchBarCustomizationIdentifier("\(Bundle.main.bundleIdentifier!).windowBar")
}

fileprivate extension NSTouchBarItemIdentifier {
    static let songArtworkTitleButton     = NSTouchBarItemIdentifier("\(Bundle.main.bundleIdentifier!).touchBar.songArtworkTitle")
    static let songProgressSlider         = NSTouchBarItemIdentifier("\(Bundle.main.bundleIdentifier!).touchBar.songProgressSlider")
    static let controlsSegmetedView       = NSTouchBarItemIdentifier("\(Bundle.main.bundleIdentifier!).touchBar.controlsSegmentedView")
    static let likeButton                 = NSTouchBarItemIdentifier("\(Bundle.main.bundleIdentifier!).touchBar.likeButton")
    static let soundPopoverButton         = NSTouchBarItemIdentifier("\(Bundle.main.bundleIdentifier!).touchBar.soundPopoverButton")
    static let soundSlider                = NSTouchBarItemIdentifier("\(Bundle.main.bundleIdentifier!).touchBar.soundSlider")
    static let shuffleRepeatSegmentedView = NSTouchBarItemIdentifier("\(Bundle.main.bundleIdentifier!).touchBar.shuffleRepeatSegmentedView")
}

@available(OSX 10.12.2, *)
extension WindowController: NSTouchBarDelegate {
    
    override func makeTouchBar() -> NSTouchBar? {
        let touchBar = NSTouchBar()
        
        touchBar.delegate = self
        touchBar.customizationIdentifier = .windowBar
        touchBar.defaultItemIdentifiers = [.songArtworkTitleButton,
                                           .songProgressSlider,
                                           .controlsSegmetedView,
                                           .likeButton,
                                           .soundPopoverButton]
        
        return touchBar
    }
    
    func touchBar(_ touchBar: NSTouchBar,
                  makeItemForIdentifier identifier: NSTouchBarItemIdentifier) -> NSTouchBarItem? {
        switch identifier {
        case .songArtworkTitleButton:
            let item  = NSCustomTouchBarItem(identifier: identifier)
            if let view = songArtworkTitleButton {
                item.view = view
            } else {
                item.view = NSButton(title: "", target: self, action: nil)
                songArtworkTitleButton = item.view as? NSButton
                prepareSongArtworkTitleButton()
            }
            return item
        default:
            return nil
        }
    }
    
}
