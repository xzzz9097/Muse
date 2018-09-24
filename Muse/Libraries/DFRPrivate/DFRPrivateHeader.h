//
//  DFRPrivateHeader.h
//  Muse
//
//  Created by lyrae on 11/07/2017.
//  Original implementation by Alexsander Akers.
//  https://github.com/a2/touch-baer
//

#import <AppKit/AppKit.h>

extern void DFRElementSetControlStripPresenceForIdentifier(NSTouchBarItemIdentifier, BOOL);
extern void DFRSystemModalShowsCloseBoxWhenFrontMost(BOOL);

@interface NSTouchBarItem ()

+ (void)addSystemTrayItem:(NSTouchBarItem *)item;

@end

@interface NSTouchBarItem (DFRAccess)

- (void)addToControlStrip;

- (void)toggleControlStripPresence:(BOOL)present;

@end

@interface NSTouchBar ()

+ (void)presentSystemModalTouchBar:(NSTouchBar *)touchBar
          systemTrayItemIdentifier:(NSTouchBarItemIdentifier)identifier NS_AVAILABLE_MAC(10.14);

+ (void)presentSystemModalFunctionBar:(NSTouchBar *)touchBar
             systemTrayItemIdentifier:(NSTouchBarItemIdentifier)identifier NS_DEPRECATED_MAC(10.12.2, 10.14);

+ (void)dismissSystemModalTouchBar:(NSTouchBar *)touchBar NS_AVAILABLE_MAC(10.14);

+ (void)minimizeSystemModalTouchBar:(NSTouchBar *)touchBar NS_AVAILABLE_MAC(10.14);

+ (void)dismissSystemModalFunctionBar:(NSTouchBar *)touchBar NS_DEPRECATED_MAC(10.12.2, 10.14);

+ (void)minimizeSystemModalFunctionBar:(NSTouchBar *)touchBar NS_DEPRECATED_MAC(10.12.2, 10.14);

@end

@interface NSTouchBar (DFRAccess)

- (void)presentAsSystemModalForItem:(NSTouchBarItem *)item;

- (void)presentAsSystemModalForItemIdentifier:(NSTouchBarItemIdentifier)identifier;

- (void)dismissSystemModal;

- (void)minimizeSystemModal;

@end

@interface NSControlStripTouchBarItem: NSCustomTouchBarItem

@property (nonatomic) BOOL isPresentInControlStrip;

@end

