
#import "DribbbleScreenSaverView.h"

@implementation DribbbleScreenSaverView

- (id)initWithFrame:(NSRect)frame isPreview:(BOOL)isPreview {
	//NSLog(@"%s",__FUNCTION__);
	self = [super initWithFrame:frame isPreview:isPreview];
	if (self) {
		[self setAnimationTimeInterval:1/30.0];
	}
	NSBundle * bundle = [NSBundle bundleWithIdentifier:@"com.gngrwzrd.HotShotsScreenSaver"];
	self.saver = [[GWDribbbleSaver alloc] initWithNibName:@"GWDribbbleSaver" bundle:bundle];
	self.saver.resourcesBundle = bundle;
	self.saver.view.frame = NSMakeRect(0,0,NSWidth(frame),NSHeight(frame));
	self.saver.ssview = self;
	[self.saver run];
	[self addSubview:self.saver.view];
	return self;
}

- (void)startAnimation {
	//NSLog(@"%s",__FUNCTION__);
	[super startAnimation];
	[self.saver startTimers];
}

- (void)stopAnimation {
	//NSLog(@"%s",__FUNCTION__);
	[super stopAnimation];
	[self.saver stopTimers];
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
	//NSLog(@"%s",__FUNCTION__);
	NSArray * topLevels = nil;
	self.prefs = [[GWSaverPrefs alloc] init];
	[self.saver.resourcesBundle loadNibNamed:@"GWSaverPrefs" owner:self.prefs topLevelObjects:&topLevels];
	return self.prefs.window;
}

@end
