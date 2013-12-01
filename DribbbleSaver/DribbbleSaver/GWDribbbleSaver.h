
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

@property (assign) ScreenSaverView * ssview;
@property (assign) IBOutlet YRKSpinningProgressIndicator * spinner;
@property NSBundle * resourcesBundle;
@property NSMutableArray * shots;
@property NSMutableArray * shotViews;
@property Dribbble * everyone;
@property Dribbble * debut;
@property Dribbble * popular;
@property Dribbble * followingShots;
@property (nonatomic) BOOL isLoading;

@property IBOutlet NSImageView * dribbbleBall;
@property IBOutlet NSTextField * message;
@property IBOutlet NSView * container;

#if GWDribbbleSaverUseCache
@property GWDataDiskCache * cache;
#endif

+ (GWDribbbleSaver *) instance;
+ (NSURL *) applicationSupport;
- (IBAction) refresh:(id)sender;
- (void) stopTimers;
- (void) startTimers;
- (void) loadFailedWithError:(NSError *) error;
- (void) shotLoadCompleted;
- (void) run;

@end
