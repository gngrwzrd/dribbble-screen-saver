
#import <Cocoa/Cocoa.h>
#import "Dribbble.h"
#import "GWDribbbleShot.h"
#import "YRKSpinningProgressIndicator.h"
#import "GWSaverPrefs.h"

@interface GWDribbbleSaver : NSViewController {
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

+ (GWDribbbleSaver *) instance;
- (IBAction) refresh:(id)sender;
- (void) stopTimers;
- (void) startTimers;

@end
