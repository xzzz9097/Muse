//
//  DFRPrivateHeader.h
//  Muse
//
//  Created by lyrae on 11/07/2017.
//  Original implementation by Alexsander Akers.
//  https://github.com/a2/touch-baer
//

#import <AppKit/AppKit.h>

extern void DFRElementSetControlStripPresenceForIdentifier(NSString *, BOOL);
extern void DFRSystemModalShowsCloseBoxWhenFrontMost(BOOL);

@interface NSTouchBarItem ()

+ (void)addSystemTrayItem:(NSTouchBarItem *)item;

@end

@interface NSTouchBar ()

+ (void)presentSystemModalFunctionBar:(NSTouchBar *)touchBar systemTrayItemIdentifier:(NSString *)identifier;

@end

