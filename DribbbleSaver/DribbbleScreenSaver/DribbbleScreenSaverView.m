
#import "DribbbleScreenSaverView.h"

@implementation DribbbleScreenSaverView

- (id)initWithFrame:(NSRect)frame isPreview:(BOOL)isPreview {
	self = [super initWithFrame:frame isPreview:isPreview];
	if (self) {
		[self setAnimationTimeInterval:1/30.0];
	}
	NSBundle * bundle = [NSBundle bundleWithIdentifier:@"com.gngrwzrd.HotShotsScreenSaver"];
	NSLog(@"%@",bundle);
	self.saver = [[GWDribbbleSaver alloc] initWithNibName:@"GWDribbbleSaver" bundle:bundle];
	self.saver.resourcesBundle = bundle;
	self.saver.view.frame = frame;
	[self addSubview:self.saver.view];
	return self;
}

- (void)startAnimation {
	[super startAnimation];
}

- (void)stopAnimation {
	[super stopAnimation];
}

- (void)drawRect:(NSRect)rect {
	[super drawRect:rect];
}

- (void)animateOneFrame {
	return;
}

- (BOOL)hasConfigureSheet {
	return YES;
}

- (NSWindow *)configureSheet {
	NSArray * topLevels = nil;
	self.prefs = [[GWSaverPrefs alloc] init];
	[self.saver.resourcesBundle loadNibNamed:@"GWSaverPrefs" owner:self.prefs topLevelObjects:&topLevels];
	return self.prefs.window;
}

@end
