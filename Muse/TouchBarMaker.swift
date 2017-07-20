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
    static let controlsSegmentedView       = NSTouchBarItemIdentifier("\(Bundle.main.bundleIdentifier!).touchBar.controlsSegmentedView")
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
                                           .fixedSpaceSmall,
                                           .songProgressSlider,
                                           .fixedSpaceSmall,
                                           .controlsSegmentedView,
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
                // We reference current self
                // to make the button action work
                view.target = self
                item.view   = view
            } else {
                item.view              = NSButton()
                songArtworkTitleButton = item.view as? NSButton
                prepareSongArtworkTitleButton()
            }
            return item
        case .songProgressSlider:
            let item = NSCustomTouchBarItem(identifier: identifier)
            if let view = songProgressSlider {
                view.target = self
                item.view   = view
            } else {
                item.view          = Slider()
                songProgressSlider = item.view as? Slider
                prepareSongProgressSlider()
            }
            return item
        case .controlsSegmentedView:
            let item = NSCustomTouchBarItem(identifier: identifier)
            item.visibilityPriority = .high
            if let view = controlsSegmentedView {
                view.target = self
                item.view   = view
            } else {
                item.view             = NSSegmentedControl()
                controlsSegmentedView = item.view as? NSSegmentedControl
                prepareButtons()
            }
            return item
        default:
            return nil
        }
    }
    
}
