
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
	[registered setObject:@"" forKey:@"playerName"];
	[defaults registerDefaults:registered];
	self.gifs.state = ([[defaults objectForKey:@"animateGifs"] boolValue]) ? NSOnState : NSOffState;
	self.playerName.stringValue = [defaults objectForKey:@"playerName"];
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

- (IBAction) playerName:(id)sender {
	ScreenSaverDefaults * defaults = [GWSaverPrefs defaults];
	[defaults setObject:[self.playerName stringValue] forKey:@"playerName"];
	[defaults synchronize];
}

@end
