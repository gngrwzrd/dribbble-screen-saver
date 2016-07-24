
#import "GWSaverPrefs.h"
#import "Dribbble.h"

@interface GWSaverPrefs ()
@property Dribbble * auth;
@property NSTimer * authCheckTimer;
@end

@implementation GWSaverPrefs

+ (ScreenSaverDefaults *) defaults {
	return [ScreenSaverDefaults defaultsForModuleWithName:@"com.gngrwzrd.HotShotsScreenSaver"];
}

- (void) awakeFromNib {
	ScreenSaverDefaults * defaults = [GWSaverPrefs defaults];
	NSMutableDictionary * registered = [NSMutableDictionary dictionary];
	[registered setObject:[NSNumber numberWithBool:0] forKey:@"animateGifs"];
	[registered setObject:[NSNumber numberWithBool:true] forKey:@"IncludeRecent"];
	[registered setObject:[NSNumber numberWithBool:true] forKey:@"IncludePopular"];
	[registered setObject:[NSNumber numberWithBool:true] forKey:@"IncludeFavorites"];
	[defaults registerDefaults:registered];
	self.gifs.state = ([[defaults objectForKey:@"animateGifs"] boolValue]) ? NSOnState : NSOffState;
	NSString * stringVersion = [[self.resourcesBundle infoDictionary] objectForKey:@"CFBundleShortVersionString"];
	NSString * bundleVersion = [[self.resourcesBundle infoDictionary] objectForKey:@"CFBundleVersion"];
	self.version.stringValue = [NSString stringWithFormat:@"Version: %@.%@",stringVersion,bundleVersion];
	
	self.check.hidden = true;
	self.authButton.hidden = false;
	
	NSString * tokenPath = [@"~/Library/Application Support/HotShotsScreenSaver/accesstoken.txt" stringByExpandingTildeInPath];
	if([[NSFileManager defaultManager] fileExistsAtPath:tokenPath]) {
		NSData * data = [NSData dataWithContentsOfFile:tokenPath];
		NSString * token = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
		Dribbble * checkAuth = [[Dribbble alloc] init];
		checkAuth.accessToken = token;
		[checkAuth getAuthedUser:^(DribbbleResponse *response) {
			if(!response.error && response.data) {
				self.check.hidden = false;
				self.authButton.hidden = true;
			}
		}];
	}
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

- (IBAction) authorizeDribbble:(id)sender {
	NSString * path = [[NSBundle bundleForClass:[self class]] pathForResource:@"AuthDribbbleScreensaver" ofType:@"app"];
	[[NSWorkspace sharedWorkspace] openFile:path];
	
	self.authCheckTimer = [NSTimer scheduledTimerWithTimeInterval:.5 target:self selector:@selector(onCheckAuth) userInfo:nil repeats:true];
}

- (void) onCheckAuth {
	NSString * tokenPath = [@"~/Library/Application Support/HotShotsScreenSaver/accesstoken.txt" stringByExpandingTildeInPath];
	if([[NSFileManager defaultManager] fileExistsAtPath:tokenPath]) {
		[self.authCheckTimer invalidate];
		self.check.hidden = false;
		self.authButton.hidden = true;
	}
}

@end
