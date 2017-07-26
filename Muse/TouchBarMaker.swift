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
    
    /**
     Override window touch bar creation method for customization
     - returns: the main window NSTouchBar
      */
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
    
    /**
     Creates the popover touch bar with sound slider and shuffle/repeat controls
     - returns: the popover NSTouchBar
      */
    var popoverBar: NSTouchBar? {
        let touchBar = NSTouchBar()
        
        touchBar.delegate                = self
        touchBar.customizationIdentifier = .popoverBar
        touchBar.defaultItemIdentifiers  = [.shuffleRepeatSegmentedView,
                                            .soundSlider]
        
        return touchBar
    }
    
    /**
     NSTouchBarDelegate implementation
     - returns: the NSTouchBarItem for requested identifier,
                generated for window bar or popover bar
      */
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
    
    /**
     Creates touch bar items for window bar
     - parameter identifier: the identifier of the requested item
     - returns: the requested NSTouchBarItem
      */
    func touchBarItem(for identifier: NSTouchBarItemIdentifier) -> NSTouchBarItem? {
        switch identifier {
        case .songArtworkTitleButton:
            return createItem(identifier: identifier, view: songArtworkTitleButton) { item in
                songArtworkTitleButton = item.view as? NSButton
                prepareSongArtworkTitleButton()
            }
        case .songProgressSlider:
            return createItem(identifier: identifier, view: songProgressSlider) { item in
                songProgressSlider = (item as? NSMediaSliderTouchBarItem)?.slider as? Slider
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
                likeButton?.image  = .like
                likeButton?.action = #selector(likeButtonClicked(_:))
                updateLikeButton()
            }
        case .soundPopoverButton:
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
    
    /**
     Creates touch bar items for popover bar
     - parameter identifier: the identifier of the requested item
     - returns: the requested NSTouchBarItem
      */
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
    
    func updatePopoverButtonForControlStrip() {
        // We can't open a popover bar from a system modal NSTouchBar
        // so we remap popover button action when necessary to open
        // the popover bar as another system modal bar
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
    
    /**
     NSTouchBar item creation helper
     - parameter identifier: the identifier of the requested item
     - parameter view: the NSView in which item.view is stored in
     - parameter creationHandler: the handler to execute when the item has been created
     - returns: the requested NSTouchBarItem
      */
    public func createItem(identifier: NSTouchBarItemIdentifier,
                           view: NSView? = nil,
                           creationHandler: (NSTouchBarItem) -> ()) -> NSTouchBarItem {
        var item: NSTouchBarItem = NSCustomTouchBarItem(identifier: identifier)
        
        switch identifier {
        case .songProgressSlider:
            item = NSMediaSliderTouchBarItem(identifier: identifier)
        case .soundSlider:
            item = NSSliderTouchBarItem(identifier: identifier)
        case .soundPopoverButton:
            item = NSPopoverTouchBarItem(identifier: identifier)
        default:
            break
        }
        
        if  identifier == .songProgressSlider ||
            identifier == .soundSlider        ||
            identifier == .soundPopoverButton {
            creationHandler(item)
            return item
        }
        
        guard let customItem = item as? NSCustomTouchBarItem else { return item }
        
        if let view = view {
            // touch bar is being reloaded
            // -> restore the archived NSView on the item and reset target
            // TODO: handle disapppearences after system modal bar usage
            if let control = view as? NSControl { control.target = self }
            customItem.view = view
        } else {
            // touch bar is being created for the first time
            switch identifier {
            case .songArtworkTitleButton, .likeButton:
                customItem.view = NSButton(title: "", target: self, action: nil)
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
