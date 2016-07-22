
#import "AppDelegate.h"

@interface AppDelegate ()
@property Dribbble * dribbble;
@end

@implementation AppDelegate

- (void) applicationDidFinishLaunching:(NSNotification *)aNotification {
	[[NSAppleEventManager sharedAppleEventManager] setEventHandler:self andSelector:@selector(handleOpenURLEvent:replyEvent:) forEventClass:kInternetEventClass andEventID:kAEGetURL];
	[NSTimer scheduledTimerWithTimeInterval:.2 target:self selector:@selector(auth) userInfo:nil repeats:false];
}

- (void) handleOpenURLEvent:(NSAppleEventDescriptor *) event replyEvent:(NSAppleEventDescriptor *) replyEvent {
	NSString * url = [[event paramDescriptorForKeyword:keyDirectObject] stringValue];
	[self.dribbble handleCustomSchemeCallback:url];
}

- (void) auth {
	NSString * tokenDir = [@"~/Library/Application Support/DribbbleScreenSaver" stringByExpandingTildeInPath];
	[[NSFileManager defaultManager] createDirectoryAtPath:tokenDir withIntermediateDirectories:TRUE attributes:nil error:nil];
	NSString * tokenPath = [@"~/Library/Application Support/DribbbleScreenSaver/accesstoken.txt" stringByExpandingTildeInPath];
	[[NSFileManager defaultManager] removeItemAtPath:tokenPath error:nil];
	self.dribbble = [[Dribbble alloc] init];
	self.dribbble.clientId = @"c7c885499244790f1bd11ac7f79e2078acf62d73e8ac6f03e2e5cc1e1bfabe2a";
	self.dribbble.clientSecret = @"f817779f5b9abd0a4fe74f306c64dd5fc4245a7f8aa1d6a2afb76a87168261a1";
	[self.dribbble authorizeWithScopes:@[DribbbleScopePublic] completion:^(DribbbleResponse *response) {
		NSData * accessTokenData = [self.dribbble.accessToken dataUsingEncoding:NSUTF8StringEncoding];
		[[NSFileManager defaultManager] createFileAtPath:tokenPath contents:accessTokenData attributes:nil];
		[[NSWorkspace sharedWorkspace] openFile:@"/Applications/System Preferences.app"];
		[[NSApplication sharedApplication] terminate:nil];
	}];
}

@end
