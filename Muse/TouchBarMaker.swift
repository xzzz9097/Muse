 //
//  TouchBarMaker.swift
//  Muse
//
//  Created by Marco Albera on 18/07/2017.
//  Copyright © 2017 Edge Apps. All rights reserved.
//

import Cocoa

fileprivate extension NSTouchBarCustomizationIdentifier {
    static let windowBar  = NSTouchBarCustomizationIdentifier("\(Bundle.main.bundleIdentifier!).windowBar")
    static let popoverBar = NSTouchBarCustomizationIdentifier("\(Bundle.main.bundleIdentifier!).popoverBar")
}

fileprivate extension NSTouchBarItemIdentifier {
    // Main TouchBar identifiers
    static let songArtworkTitleButton     = NSTouchBarItemIdentifier("\(Bundle.main.bundleIdentifier!).touchBar.songArtworkTitle")
    static let songProgressSlider         = NSTouchBarItemIdentifier("\(Bundle.main.bundleIdentifier!).touchBar.songProgressSlider")
    static let controlsSegmentedView       = NSTouchBarItemIdentifier("\(Bundle.main.bundleIdentifier!).touchBar.controlsSegmentedView")
    static let likeButton                 = NSTouchBarItemIdentifier("\(Bundle.main.bundleIdentifier!).touchBar.likeButton")
    static let soundPopoverButton         = NSTouchBarItemIdentifier("\(Bundle.main.bundleIdentifier!).touchBar.soundPopoverButton")
    
    // Popover TouchBar identifiers
    static let soundSlider                = NSTouchBarItemIdentifier("\(Bundle.main.bundleIdentifier!).touchBar.soundSlider")
    static let shuffleRepeatSegmentedView = NSTouchBarItemIdentifier("\(Bundle.main.bundleIdentifier!).touchBar.shuffleRepeatSegmentedView")
}

@available(OSX 10.12.2, *)
extension WindowController: NSTouchBarDelegate {
    
    override func makeTouchBar() -> NSTouchBar? {
        let touchBar = NSTouchBar()
        
        touchBar.delegate                = self
        touchBar.customizationIdentifier = .windowBar
        touchBar.defaultItemIdentifiers  = [.songArtworkTitleButton,
                                           .fixedSpaceSmall,
                                           .songProgressSlider,
                                           .fixedSpaceSmall,
                                           .controlsSegmentedView,
                                           .likeButton,
                                           .soundPopoverButton]
        
        return touchBar
    }
    
    var popoverBar: NSTouchBar? {
        let touchBar = NSTouchBar()
        
        touchBar.delegate                = self
        touchBar.customizationIdentifier = .popoverBar
        touchBar.defaultItemIdentifiers  = [.shuffleRepeatSegmentedView,
                                            .soundSlider]
        
        return touchBar
    }
    
    func touchBar(_ touchBar: NSTouchBar,
                  makeItemForIdentifier identifier: NSTouchBarItemIdentifier) -> NSTouchBarItem? {
        guard let barIdentifier = touchBar.customizationIdentifier else { return nil }
        
        switch barIdentifier {
        case .windowBar:
            return touchBarItem(for: identifier)
        case .popoverBar:
            return popoverBarItem(for: identifier)
        default:
            return nil
        }
    }
    
    func touchBarItem(for identifier: NSTouchBarItemIdentifier) -> NSTouchBarItem? {
        switch identifier {
        case .songArtworkTitleButton:
            return createItem(identifier: identifier, view: songArtworkTitleButton) { item in
                songArtworkTitleButton = item.view as? NSButton
                prepareSongArtworkTitleButton()
            }
        case .songProgressSlider:
            return createItem(identifier: identifier, view: songProgressSlider) { item in
                songProgressSlider = item.view as? Slider
                prepareSongProgressSlider()
            }
        case .controlsSegmentedView:
            return createItem(identifier: identifier, view: controlsSegmentedView) { item in
                controlsSegmentedView = item.view as? NSSegmentedControl
                prepareButtons()
            }
        case .likeButton:
            return createItem(identifier: identifier, view: likeButton) { item in
                likeButton         = item.view as? NSButton
                likeButton?.action = #selector(likeButtonClicked(_:))
                updateLikeButton()
            }
        case .soundPopoverButton:
            //let item = NSPopoverTouchBarItem(identifier: identifier)
            return createItem(identifier: identifier) { item in
                soundPopoverButton                       = item as? NSPopoverTouchBarItem
                soundPopoverButton?.popoverTouchBar      = popoverBar!
                soundPopoverButton?.pressAndHoldTouchBar = popoverBar!
                updateSoundPopoverButton(for: helper.volume)
            }
        default:
            return nil
        }
    }
    
    func updatePopoverButtonForControlStrip() {
        // TODO: handle long press in control strip (?)
        let popoverButton     = soundPopoverButton?.collapsedRepresentation as? NSButton
        popoverButton?.target = self
        popoverButton?.action = #selector(openPopoverBar(_:))
    }
    
    func openPopoverBar(_ sender: NSButton) {
        NSTouchBar.presentSystemModalFunctionBar(
            popoverBar,
            systemTrayItemIdentifier: NSTouchBarItemIdentifier.soundPopoverButton.rawValue
        )
    }
    
    func popoverBarItem(for identifier: NSTouchBarItemIdentifier) -> NSTouchBarItem? {
        switch identifier {
        case .soundSlider:
            return createItem(identifier: identifier) { item in
                soundSlider = item as? NSSliderTouchBarItem
                prepareSoundSlider()
            }
        case .shuffleRepeatSegmentedView:
            return createItem(identifier: identifier, view: shuffleRepeatSegmentedView) { item in
                shuffleRepeatSegmentedView = item.view as? NSSegmentedControl
                prepareShuffleRepeatSegmentedView()
            }
        default:
            return nil
        }
    }
    
    public func createItem(identifier: NSTouchBarItemIdentifier,
                           view: NSView? = nil,
                           creationHandler: (NSTouchBarItem) -> ()) -> NSTouchBarItem {
        var item: NSTouchBarItem = NSCustomTouchBarItem(identifier: identifier)
        
        switch identifier {
        case .soundSlider:
            item = NSSliderTouchBarItem(identifier: identifier)
        case .soundPopoverButton:
            item = NSPopoverTouchBarItem(identifier: identifier)
        default:
            break
        }
        
        if identifier == .soundSlider || identifier == .soundPopoverButton {
            creationHandler(item)
            return item
        }
        
        guard let customItem = item as? NSCustomTouchBarItem else { return item }
        
        if let view = view {
            if let control = view as? NSControl { control.target = self }
            customItem.view = view
        } else {
            switch identifier {
            case .songArtworkTitleButton, .likeButton:
                customItem.view = NSButton(title: "", target: self, action: nil)
            case .songProgressSlider:
                customItem.view = Slider()
            case .controlsSegmentedView, .shuffleRepeatSegmentedView:
                customItem.view = NSSegmentedControl()
            default:
                break
            }
            creationHandler(item)
        }
        
        return customItem
    }
    
}
