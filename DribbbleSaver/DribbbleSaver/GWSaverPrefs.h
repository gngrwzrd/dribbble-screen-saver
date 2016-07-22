
#import <Cocoa/Cocoa.h>
#import <ScreenSaver/ScreenSaver.h>

@interface GWSaverPrefs : NSWindowController
@property IBOutlet NSButton * gifs;
@property IBOutlet NSTextField * version;
@property IBOutlet NSTextField * accessToken;
@property NSBundle * resourcesBundle;
+ (ScreenSaverDefaults *) defaults;
@end
