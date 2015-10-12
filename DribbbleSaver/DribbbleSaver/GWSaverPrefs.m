
#import "GWSaverPrefs.h"

@interface GWSaverPrefs ()
@end

@implementation GWSaverPrefs

+ (ScreenSaverDefaults *) defaults {
	return [ScreenSaverDefaults defaultsForModuleWithName:@"com.gngrwzrd.HotShotsScreenSaver"];
}

- (void) awakeFromNib {
	ScreenSaverDefaults * defaults = [GWSaverPrefs defaults];
	NSMutableDictionary * registered = [NSMutableDictionary dictionary];
	[registered setObject:[NSNumber numberWithBool:0] forKey:@"animateGifs"];
	[defaults registerDefaults:registered];
	self.gifs.state = ([[defaults objectForKey:@"animateGifs"] boolValue]) ? NSOnState : NSOffState;
	
	NSString * stringVersion = [[self.resourcesBundle infoDictionary] objectForKey:@"CFBundleShortVersionString"];
	NSString * bundleVersion = [[self.resourcesBundle infoDictionary] objectForKey:@"CFBundleVersion"];
	
	self.version.stringValue = [NSString stringWithFormat:@"Version: %@.%@",stringVersion,bundleVersion];
}

- (IBAction) ok:(id) sender {
	[[NSApplication sharedApplication] endSheet:self.window];
}

- (IBAction) animateGifs:(id)sender {
	ScreenSaverDefaults * defaults = [GWSaverPrefs defaults];
	BOOL on = self.gifs.state == NSOnState;
	[defaults setObject:[NSNumber numberWithBool:on] forKey:@"animateGifs"];
	[defaults synchronize];
}

- (IBAction) checkForUpdates:(id)sender {
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://www.gngrwzrd.com/hot-shots-screen-saver/"]];
}

@end
