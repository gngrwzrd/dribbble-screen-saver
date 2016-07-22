
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
	
	NSString * accessToken = [defaults stringForKey:@"DribbbleAccessToken"];
	[self writeToLogFile:accessToken];
	if(accessToken) {
		self.accessToken.stringValue = accessToken;
	}
	
	[[NSAppleEventManager sharedAppleEventManager] setEventHandler:self andSelector:@selector(handleOpenURLEvent:replyEvent:) forEventClass:kInternetEventClass andEventID:kAEGetURL];
}

- (void) handleOpenURLEvent:(NSAppleEventDescriptor *) event replyEvent:(NSAppleEventDescriptor *) replyEvent {
	NSString * url = [[event paramDescriptorForKeyword:keyDirectObject] stringValue];
	[self.auth handleCustomSchemeCallback:url];
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
	return;
	//[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://dribbble.com/account/applications/new"]];
	self.auth = [[Dribbble alloc] init];
	self.auth.clientId = @"c7c885499244790f1bd11ac7f79e2078acf62d73e8ac6f03e2e5cc1e1bfabe2a";
	self.auth.clientSecret = @"f817779f5b9abd0a4fe74f306c64dd5fc4245a7f8aa1d6a2afb76a87168261a1";
	[self.auth authorizeWithScopes:@[DribbbleScopePublic] completion:^(DribbbleResponse *response) {
		[[GWSaverPrefs defaults] setObject:self.auth.accessToken forKey:@"DribbbleAccessToken"];
		[[GWSaverPrefs defaults] synchronize];
		[[NSWorkspace sharedWorkspace] openFile:@"/Applications/System Preferences.app"];
	}];
}

- (IBAction) onTokenChange:(id)sender {
	[[GWSaverPrefs defaults] setObject:self.accessToken.stringValue forKey:@"DribbbleAccessToken"];
}

@end
