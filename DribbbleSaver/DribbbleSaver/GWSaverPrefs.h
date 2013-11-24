
#import <Cocoa/Cocoa.h>
#import <ScreenSaver/ScreenSaver.h>

@interface GWSaverPrefs : NSWindowController
@property IBOutlet NSButton * gifs;
@property IBOutlet NSTextField * playerName;
+ (ScreenSaverDefaults *) defaults;
@end
