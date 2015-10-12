
#import <Cocoa/Cocoa.h>
#import "Dribbble.h"
#import "GWDribbbleShot.h"
#import "YRKSpinningProgressIndicator.h"
#import "GWSaverPrefs.h"
#import "GWDataDiskCache.h"

#define GWDribbbleSaverUseCache 1

@interface GWDribbbleSaver : NSViewController {
	BOOL _useCachedShots;
	NSTimer * refreshTimer;
	NSTimer * switchTimer;
	NSTimer * switchTimer2;
}

@property NSBundle * resourcesBundle;
@property NSMutableArray * shots;
@property NSMutableArray * shotViews;
@property Dribbble * latest;
@property Dribbble * popular;

#if GWDribbbleSaverUseCache
@property GWDataDiskCache * cache;
#endif

+ (GWDribbbleSaver *) instance;
+ (NSURL *) applicationSupport;
- (IBAction) refresh:(id)sender;
- (void) stopTimers;
- (void) startTimers;
- (void) run;

//- (void) shotLoadCompleted;

@end
