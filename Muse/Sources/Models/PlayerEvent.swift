//
//  PlayerEvent.swift
//  Muse
//
//  Created by Marco Albera on 03/10/2017.
//  Copyright © 2017 Edge Apps. All rights reserved.
//

import Foundation

// Defines a set of infos to inform the VC
// about player events from the outside
typealias PlayerAction = PlayerEvent

// Supported player helper events
enum PlayerEvent {
    case play
    case pause
    case next
    case previous
    case scrub(Bool, Double)
    case shuffling(Bool)
    case repeating(Bool)
    case like(Bool)
}

@available(OSX 10.12.2, *)
extension PlayerEvent {
    
    var image: NSImage? {
        switch self {
        case .play:
            return .play
        case .pause:
            return .pause
        case .previous:
            return .previous
        case .next:
            return .next
        case .shuffling:
            return .shuffling
        case .repeating:
            return .repeating
        case .like:
            return .like
        default:
            return nil
        }
    }
    
    var smallImage: NSImage? {
        switch self {
        case .play:
            return image?.resized(to: NSMakeSize(8, 8))
        case .pause:
            return image?.resized(to: NSMakeSize(7, 7))
        case .previous:
            return image?.resized(to: NSMakeSize(12, 12))
        case .next:
            return image?.resized(to: NSMakeSize(12, 12))
        case .shuffling, .repeating:
            return image?.resized(to: NSMakeSize(20, 20))
        case .like:
            return image?.resized(to: NSMakeSize(15, 15))
        default:
            return image
        }
    }
}

extension PlayerEvent: RawRepresentable {
    
    typealias RawValue = Int
    
    init?(rawValue: Int) {
        switch rawValue {
        case 0: self = .play
        case 1: self = .pause
        case 2: self = .previous
        case 3: self = .next
        case 4: self = .shuffling(false)
        case 5: self = .repeating(false)
        case 6: self = .like(false)
        case 7: self = .scrub(false, 0)
        default: return nil
        }
    }
    
    var rawValue: Int {
        switch self {
        case .play: return 0
        case .pause: return 1
        case .previous: return 2
        case .next: return 3
        case .shuffling: return 4
        case .repeating: return 5
        case .like: return 6
        case .scrub: return 7
        }
    }
}

extension PlayerEvent: Hashable {
    
    var hashValue: Int {
        return self.rawValue
    }
}
