
#import "AppDelegate.h"

@interface AppDelegate ()
@property (weak) IBOutlet NSWindow * window;
@property (weak) IBOutlet NSTextField * likeShotField;
@property (weak) IBOutlet NSTextField * unlikeShotField;
@property (weak) IBOutlet NSTextField * followUser;
@property (weak) IBOutlet NSTextField * unfollowUser;
@property Dribbble * d;
@end

@implementation AppDelegate

- (void) applicationDidFinishLaunching:(NSNotification *) aNotification {
	// Insert code here to initialize your application
	[[NSAppleEventManager sharedAppleEventManager] setEventHandler:self andSelector:@selector(handleURLEvent:withReplyEvent:) forEventClass:kInternetEventClass andEventID:kAEGetURL];
}

- (void) applicationWillTerminate:(NSNotification *) aNotification {
	// Insert code here to tear down your application
}

- (void) handleURLEvent:(NSAppleEventDescriptor*) event withReplyEvent:(NSAppleEventDescriptor*) replyEvent {
	NSString * url = [[event paramDescriptorForKeyword:keyDirectObject] stringValue];
	[self.d handleCustomSchemeCallback:url];
}

- (IBAction) testAuth:(id)sender {
	self.d = [[Dribbble alloc] init];
	self.d.clientId = @"1bcc9d4412783d9ed17457ea7bfe293392c523de74f5e4e8cf798f45eca3e559";
	self.d.clientSecret = @"5d20fe22fdba1dfb957d8187230394b7b732db2c9e9cae9da31e5ed0a5233933";
	[self.d authorizeWithScopes:@[DribbbleScopePublic,DribbbleScopeWrite,DribbbleScopeUpload] completion:^(DribbbleResponse *response) {
		if(!response.error) {
			NSLog(@"%@",self.d.accessToken);
			NSLog(@"authorize success!");
		}
	}];
}

- (IBAction) listShots:(id)sender {
	[self.d listShotsWithParameters:nil completion:^(DribbbleResponse *response) {
		NSLog(@"shots complete");
		NSLog(@"%@",response.data);
	}];
}

- (IBAction) listShotLikesForAuthedUser:(id)sender {
	[self.d listShotsLikedParameters:nil withCompletion:^(DribbbleResponse *response) {
		NSLog(@"likes:");
		NSLog(@"%@",response.data);
	}];
}

- (IBAction) likeShot:(id)sender {
	[self.d likeShot:self.likeShotField.stringValue withCompletion:^(DribbbleResponse *response) {
		NSLog(@"%@",response);
	}];
}

- (IBAction) unlikeShot:(id)sender {
	[self.d unlikeShot:self.likeShotField.stringValue withCompletion:^(DribbbleResponse *response) {
		NSLog(@"%@",response);
	}];
}

- (IBAction) followUser:(id)sender {
	[self.d followUser:self.followUser.stringValue withCompletion:^(DribbbleResponse *response) {
		NSLog(@"%@",response);
	}];
}

- (IBAction) unfollowUser:(id)sender {
	[self.d unfollowUser:self.unfollowUser.stringValue withCompletion:^(DribbbleResponse *response) {
		NSLog(@"%@",response);
	}];
}

- (IBAction) listAnimatedRecent:(id)sender {
	[self.d listShotsWithParameters:@{@"list":@"animated",@"sort":@"recent"} completion:^(DribbbleResponse *response) {
		NSLog(@"%@",response);
	}];
}

@end
