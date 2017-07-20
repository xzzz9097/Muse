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
            return createItem(identifier: identifier,
                              view: songArtworkTitleButton) { item in
                songArtworkTitleButton = item.view as? NSButton
                prepareSongArtworkTitleButton()
            }
        case .songProgressSlider:
            return createItem(identifier: identifier,
                              view: songProgressSlider) { item in
                songProgressSlider = item.view as? Slider
                prepareSongProgressSlider()
            }
        case .controlsSegmentedView:
            return createItem(identifier: identifier,
                              view: controlsSegmentedView) { item in
                controlsSegmentedView = item.view as? NSSegmentedControl
                prepareButtons()
            }
        case .likeButton:
            return createItem(identifier: identifier,
                              view: likeButton) { item in
                likeButton = item.view as? NSButton
                updateLikeButton()
            }
        case .soundPopoverButton:
            let item = NSPopoverTouchBarItem(identifier: identifier)
            soundPopoverButton = item
            updateSoundPopoverButton(for: helper.volume)
            // TODO: Add popover TouchBar
            return item
        default:
            return nil
        }
    }
    
    public func createItem(identifier: NSTouchBarItemIdentifier,
                           view: NSView?,
                           creationHandler: (NSTouchBarItem) -> ()) -> NSTouchBarItem {
        let item = NSCustomTouchBarItem(identifier: identifier)
        
        if let view = view {
            if let control = view as? NSControl { control.target = self }
            item.view = view
        } else {
            switch identifier {
            case .songArtworkTitleButton, .likeButton:
                item.view = NSButton(title: "", target: self, action: nil)
            case .songProgressSlider:
                item.view = Slider()
            case .controlsSegmentedView:
                item.view = NSSegmentedControl()
            default:
                break
            }
            creationHandler(item)
        }
        
        return item
    }
    
}
