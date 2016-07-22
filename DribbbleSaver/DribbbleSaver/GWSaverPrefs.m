
#import "GWSaverPrefs.h"
#import "Dribbble.h"

@interface GWSaverPrefs ()
@property Dribbble * auth;
@property NSFileHandle * log;
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
	[self createLogFile];
	
	NSString * tokenPath = [@"~/Library/Application Support/DribbbleScreenSaver/accesstoken.txt" stringByExpandingTildeInPath];
	if([[NSFileManager defaultManager] fileExistsAtPath:tokenPath]) {
		NSData * data = [NSData dataWithContentsOfFile:tokenPath];
		NSString * token = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
	}
}

NSString * const logFile = @"/Users/aaronsmith/Library/Logs/DribbleSaver.log";

- (void) createLogFile {
	[[NSFileManager defaultManager] createFileAtPath:logFile contents:nil attributes:nil];
}

- (void) writeToLogFile:(NSString *) message {
	if(!self.log) {
		self.log = [NSFileHandle fileHandleForWritingAtPath:logFile];
	}
	[self.log writeData:[message dataUsingEncoding:NSUTF8StringEncoding]];
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
}

@end
