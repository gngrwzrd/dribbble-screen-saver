
#import "GWAppDelegate.h"

@implementation GWAppDelegate

- (void) applicationDidFinishLaunching:(NSNotification *)aNotification {
	self.saver = [[GWDribbbleSaver alloc] initWithNibName:@"GWDribbbleSaver" bundle:nil];
	self.saver.view.frame = ((NSView*)self.window.contentView).bounds;
	self.saver.ssview = self;
	[self.saver run];
	[self.window.contentView addSubview:self.saver.view];
}

- (IBAction) refresh:(id)sender {
	[self.saver refresh:nil];
}

- (BOOL) isAnimating {
	return TRUE;
}

@end
