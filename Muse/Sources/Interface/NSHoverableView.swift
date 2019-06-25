//
//  ImageView.swift
//  Muse
//
//  Created by Marco Albera on 08/12/16.
//  Copyright © 2016 Edge Apps. All rights reserved.
//

import Cocoa

extension NSTrackingArea.Options {
    
    // An OptionSet with the needed mouse tracking flags
    static var defaultMouse: NSTrackingArea.Options {
        return [.mouseEnteredAndExited, .activeAlways]
    }
}

enum NSViewMouseHoverState {
    
    case entered
    case exited
}

enum NSScrollDirection {
    
    case left
    case right
    case up
    case down
    
    init?(_ event: NSEvent) {
        let deltaX = Int(event.scrollingDeltaX)
        let deltaY = Int(event.scrollingDeltaY)
        
        guard deltaX != 0 || deltaY != 0 else { return nil }
        
        // WARNING: presumes natural scrolling!
        // TODO:    implement classic scrolling
        if abs(deltaX) > abs(deltaY) {
            switch deltaX {
            case Int.min..<0:
                self = .right
            case 0..<Int.max:
                self = .left
            default:
                return nil
            }
        } else {
            switch deltaY {
            case Int.min..<0:
                self = .down
            case 0..<Int.max:
                self = .up
            default:
                return nil
            }
        }
    }
}

struct NSScrollEvent {
    
    var direction: NSScrollDirection?
    
    init(initialEvent: NSEvent) {
        direction = NSScrollDirection(initialEvent)
    }
}

protocol NSMouseHoverableView {
    
    var onMouseHoverStateChange: ((NSViewMouseHoverState) -> ())? { set get }
}

protocol NSMouseScrollableView {
    
    var onMouseScrollEvent: ((NSScrollEvent) -> ())? { set get }
}

class NSHoverableView: NSView, NSMouseHoverableView, NSMouseScrollableView {
    
    // MARK: Hovering
    
    private var mouseTrackingArea: NSTrackingArea!
    
    var onMouseHoverStateChange: ((NSViewMouseHoverState) -> ())?
    
    override func mouseEntered(with event: NSEvent) {
        onMouseHoverStateChange?(.entered)
    }
    
    override func mouseExited(with event: NSEvent) {
        onMouseHoverStateChange?(.exited)
    }
    
    override func updateTrackingAreas() {
        if let area = mouseTrackingArea {
            removeTrackingArea(area)
        }
        
        mouseTrackingArea = NSTrackingArea.init(rect: self.bounds,
                                                options: .defaultMouse,
                                                owner: self,
                                                userInfo: nil)
        
        self.addTrackingArea(mouseTrackingArea)
    }
    
    // MARK: Scrolling
    
    var onMouseScrollEvent: ((NSScrollEvent) -> ())?
    
    override func scrollWheel(with event: NSEvent) {
        if event.phase.contains(.began) {
            onMouseScrollEvent?(NSScrollEvent(initialEvent: event))
        }
    }
}
