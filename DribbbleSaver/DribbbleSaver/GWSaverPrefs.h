
#import <Cocoa/Cocoa.h>
#import <ScreenSaver/ScreenSaver.h>

@interface GWSaverPrefs : NSWindowController
@property IBOutlet NSButton * gifs;
@property IBOutlet NSButton * authButton;
@property IBOutlet NSTextField * version;
@property IBOutlet NSTextField * check;
@property NSBundle * resourcesBundle;
+ (ScreenSaverDefaults *) defaults;
@end
