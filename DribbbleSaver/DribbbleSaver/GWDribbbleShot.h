
#import <Cocoa/Cocoa.h>
#import <ScreenSaver/ScreenSaver.h>
#import "YRKSpinningProgressIndicator.h"

@interface GWDribbbleShot : NSViewController {
	NSTimer * spinnerTimer;
}

@property (assign) IBOutlet NSImageView * imageView;
@property (assign) IBOutlet YRKSpinningProgressIndicator * spinner;
@property (nonatomic) BOOL isLoading;
@end
