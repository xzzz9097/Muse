//
//  DFRPrivateHeader.m
//  Muse
//
//  Created by Marco Albera on 13/07/2017.
//  Copyright © 2017 Edge Apps. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DFRPrivateHeader.h"

@implementation NSTouchBarItem (DFRAccess)

- (void)addToControlStrip {
    [NSTouchBarItem addSystemTrayItem:self];
    
    [self toggleControlStripPresence:true];
}

- (void)toggleControlStripPresence:(BOOL)present {
    DFRElementSetControlStripPresenceForIdentifier(self.identifier,
                                                   present);
}

@end

@implementation NSTouchBar (DFRAccess)

- (void)presentAsSystemModalForItem:(NSTouchBarItem *)item {
    [self presentAsSystemModalForItemIdentifier:item.identifier];
}

- (void)presentAsSystemModalForItemIdentifier:(NSTouchBarItemIdentifier)identifier {
    if (@available(macOS 10.14, *)) {
        [NSTouchBar presentSystemModalTouchBar:self
                      systemTrayItemIdentifier:identifier];
    } else {
        [NSTouchBar presentSystemModalFunctionBar:self
                         systemTrayItemIdentifier:identifier];
    }
}

- (void)dismissSystemModal {
    if (@available(macOS 10.14, *)) {
        [NSTouchBar dismissSystemModalTouchBar:self];
    } else {
        [NSTouchBar dismissSystemModalFunctionBar:self];
    }
}

- (void)minimizeSystemModal {
    if (@available(macOS 10.14, *)) {
        [NSTouchBar minimizeSystemModalTouchBar:self];
    } else {
        [NSTouchBar minimizeSystemModalFunctionBar:self];
    }
}

@end

@implementation NSControlStripTouchBarItem

- (void)setIsPresentInControlStrip:(BOOL)present {
    _isPresentInControlStrip = present;
    
    if (present) {
        [super addToControlStrip];
    } else {
        [super toggleControlStripPresence:false];
    }
}

@end
