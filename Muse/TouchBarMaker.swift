//
//  TouchBarMaker.swift
//  Muse
//
//  Created by Marco Albera on 18/07/2017.
//  Copyright © 2017 Edge Apps. All rights reserved.
//

import Cocoa

fileprivate extension NSTouchBarItemIdentifier {
}

@available(OSX 10.12.2, *)
extension WindowController: NSTouchBarDelegate {
    
    override func makeTouchBar() -> NSTouchBar? {
        let touchBar = NSTouchBar()
        
        touchBar.delegate = self
        touchBar.defaultItemIdentifiers = []
        
        return touchBar
    }
    
    func touchBar(_ touchBar: NSTouchBar,
                  makeItemForIdentifier identifier: NSTouchBarItemIdentifier) -> NSTouchBarItem? {
        switch identifier {
        default:
            return nil
        }
    }
    
}
