
#import "GWDribbbleSaver.h"

static GWDribbbleSaver * _instance;

@interface GWDribbbleSaver ()
@end

@implementation GWDribbbleSaver

+ (GWDribbbleSaver *) instance {
	return _instance;
}

+ (NSURL *) applicationSupport {
	NSFileManager * fileManager = [NSFileManager defaultManager];
	NSURL * url = [fileManager URLForDirectory:NSApplicationSupportDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:TRUE error:nil];
	url = [url URLByAppendingPathComponent:@"HotShotsScreenSaver"];
	[fileManager createDirectoryAtPath:url.path withIntermediateDirectories:TRUE attributes:nil error:nil];
	return url;
}

- (void) awakeFromNib {
	NSLog(@"%s",__FUNCTION__);
	
	_instance = self;
	[self setup];
	[self setupDribbble];
	[self setupCache];
	[self decorate];
	[self deserializeShots];
}

- (void) run {
	if(self.shots.count > 0) {
		[self shuffleShots];
		[self populateDribbbleShots];
		[self startRefreshTimer];
		[self startSwitchTimer];
	} else {
		[self loadDribbble:nil];
	}
}

- (void) setup {
	NSLog(@"%s",__FUNCTION__);
	
	self.shots = [NSMutableArray array];
	self.shotViews = [NSMutableArray array];
}

- (void) setupDribbble {
	NSLog(@"%s",__FUNCTION__);
	
	self.everyone = [[Dribbble alloc] initEveryonePager];
	self.debut = [[Dribbble alloc] initDebutPager];
	self.popular = [[Dribbble alloc] initPopularPager];
	
	ScreenSaverDefaults * defaults = [GWSaverPrefs defaults];
	NSString * playerName = [defaults objectForKey:@"playerName"];
	if(playerName && ![playerName isEqualToString:@""]) {
		self.followingShots = [[Dribbble alloc] initFollowedPlayerShotsPager:playerName];
	}
}

- (void) setupCache {
	NSLog(@"%s",__FUNCTION__);
	
	//NSURL * as = [GWDribbbleSaver applicationSupport];
	//self.cache = [[GWDataDiskCache alloc] initWithDiskCacheURL:url];
	//self.cache.oldestAllowableFileTimeDelta = 86400;
	//[self.cache clearOldFiles];
}

- (void) decorate {
	NSLog(@"%s",__FUNCTION__);
	
	self.spinner.displayedWhenStopped = FALSE;
	self.spinner.color = [NSColor whiteColor];
	self.spinner.drawsBackground = FALSE;
	self.spinner.backgroundColor = [NSColor clearColor];
}

- (void) serializeShots {
	NSLog(@"%s",__FUNCTION__);
	
	NSURL * as = [GWDribbbleSaver applicationSupport];
	NSURL * shots = [as URLByAppendingPathComponent:@"shots.data"];
	NSData * data = [NSKeyedArchiver archivedDataWithRootObject:self.shots];
	[data writeToURL:shots atomically:TRUE];
}

- (void) deserializeShots {
	NSLog(@"%s",__FUNCTION__);
	
	NSURL * as = [GWDribbbleSaver applicationSupport];
	NSURL * shots = [as URLByAppendingPathComponent:@"shots.data"];
	NSFileManager * fileManager = [NSFileManager defaultManager];
	if([fileManager fileExistsAtPath:shots.path]) {
		NSData * data = [NSData dataWithContentsOfURL:shots];
		_shots = [NSKeyedUnarchiver unarchiveObjectWithData:data];
	}
}

- (void) setIsLoading:(BOOL)isLoading {
	NSLog(@"%s",__FUNCTION__);
	
	_isLoading = isLoading;
	if(_isLoading) {
		[self.spinner startAnimation:nil];
	} else {
		[self.spinner stopAnimation:nil];
	}
}

- (void) loadDribbble:(id) sender {
	NSLog(@"%s",__FUNCTION__);
	
	self.isLoading = TRUE;
	
	if(self.container.superview) {
		[self.container removeFromSuperview];
	}
	
	__block BOOL failed = FALSE;
	__block NSInteger loads = 3;
	__block NSInteger completed = 0;
	
	if(self.followingShots) {
		loads++;
		[self.followingShots loadPages:1 completion:^(DribbbleResponse *response) {
			if(response.error && !failed) {
				failed = TRUE;
				[self loadFailedWithError:response.error];
				return;
			}
			
			[self.shots addObjectsFromArray:response.dribbble.shots];
			completed++;
			if(completed >= loads) {
				[self dribbbleLoaded];
			}
		}];
	}
	
	[self.everyone loadPages:1 completion:^(DribbbleResponse *response) {
		if(response.error && !failed) {
			failed = TRUE;
			[self loadFailedWithError:response.error];
			return;
		}
		
		[self.shots addObjectsFromArray:response.dribbble.shots];
		completed++;
		if(completed >= loads) {
			[self dribbbleLoaded];
		}
	}];
	
	[self.debut loadPages:1 completion:^(DribbbleResponse *response) {
		if(response.error && !failed) {
			failed = TRUE;
			[self loadFailedWithError:response.error];
			return;
		}
		
		[self.shots addObjectsFromArray:response.dribbble.shots];
		completed++;
		if(completed >= loads) {
			[self dribbbleLoaded];
		}
	}];
	
	[self.popular loadPages:1 completion:^(DribbbleResponse *response) {
		if(response.error && !failed) {
			failed = TRUE;
			[self loadFailedWithError:response.error];
			return;
		}
		
		[self.shots addObjectsFromArray:response.dribbble.shots];
		completed++;
		if(completed >= loads) {
			[self dribbbleLoaded];
		}
	}];
}

- (void) loadFailedWithError:(NSError *) error {
	NSLog(@"%s",__FUNCTION__);
	
	if(self.container.superview) {
		return;
	}
	
	[self stopTimers];
	[self removeDribbbleShots];
	[self startRefreshTimer];
	self.isLoading = FALSE;
	
	NSRect bounds = self.view.frame;
	NSRect cf = self.container.frame;
	cf.origin.x = (NSWidth(bounds)-NSWidth(cf)) / 2;
	cf.origin.y = (NSHeight(bounds)-NSHeight(cf)) / 2;
	self.container.frame = cf;
	[self.view addSubview:self.container];
}

- (void) dribbbleLoaded {
	NSLog(@"%s",__FUNCTION__);
	
	self.isLoading = FALSE;
	
	[self shuffleShots];
	if(self.shotViews.count < 1) {
		[self populateDribbbleShots];
		[NSTimer scheduledTimerWithTimeInterval:10 target:self selector:@selector(startSwitchTimer) userInfo:nil repeats:FALSE];
	} else {
		[self startSwitchTimer];
	}
	
	[self startRefreshTimer];
	
	[self serializeShots];
}

- (void) shotLoadCompleted {
	NSLog(@"%s",__FUNCTION__);
	
	if(self.container.superview) {
		[self.container removeFromSuperview];
		[self stopTimers];
		[self loadDribbble:nil];
		[self startTimers];
	}
}

- (void) shuffleShots {
	NSLog(@"%s",__FUNCTION__);
	
	[self.shots sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
		NSInteger ri = arc4random_uniform(100);
		if(ri > 50) {
			return -1;
		} else {
			return 1;
		}
	}];
}

- (void) startRefreshTimer {
	NSLog(@"%s",__FUNCTION__);
	
	if(!self.ssview.isAnimating) {
		return;
	}
	
	refreshTimer = [NSTimer scheduledTimerWithTimeInterval:300 target:self selector:@selector(loadDribbble:) userInfo:nil repeats:TRUE];
}

- (void) stopRefreshTimer {
	NSLog(@"%s",__FUNCTION__);
	
	[refreshTimer invalidate];
	refreshTimer = nil;
}

- (void) startSwitchTimer {
	//NSLog(@"%s",__FUNCTION__);
	
	if(!self.ssview.isAnimating) {
		return;
	}
	
	if(switchTimer) {
		[switchTimer invalidate];
	}
	
	if(switchTimer2) {
		[switchTimer2 invalidate];
	}
	
	switchTimer = [NSTimer scheduledTimerWithTimeInterval:2.75 target:self selector:@selector(switchDribbble:) userInfo:nil repeats:TRUE];
	switchTimer2 = [NSTimer scheduledTimerWithTimeInterval:3.8 target:self selector:@selector(switchDribbble:) userInfo:nil repeats:TRUE];
}

- (void) stopSwitchTimer {
	NSLog(@"%s",__FUNCTION__);
	
	[switchTimer invalidate];
	switchTimer = nil;
	
	[switchTimer2 invalidate];
	switchTimer2 = nil;
}

- (void) startTimers {
	NSLog(@"%s",__FUNCTION__);
	
	[self stopTimers];
	[self startSwitchTimer];
	[self startRefreshTimer];
}

- (void) stopTimers {
	NSLog(@"%s",__FUNCTION__);
	
	[self stopRefreshTimer];
	[self stopSwitchTimer];
}

- (void) switchDribbble:(NSTimer *) timer {
	NSLog(@"%s",__FUNCTION__);
	
	if(self.shotViews.count < 1) {
		return;
	}
	
	NSInteger switchCount = 1;
	NSMutableArray * __shots = [NSMutableArray array];
	NSInteger ri = 0;
	for(NSInteger i = 0; i < switchCount; i++) {
		ri = arc4random_uniform((uint32_t)self.shots.count);
		[__shots addObject:[self.shots objectAtIndex:ri]];
	}
	
	NSInteger rsi = 0;
	GWDribbbleShot * dshot = NULL;
	for(NSInteger j = 0; j < __shots.count; j++) {
		rsi = arc4random_uniform((uint32_t)self.shotViews.count);
		dshot = [self.shotViews objectAtIndex:rsi];
		dshot.representedObject = [__shots objectAtIndex:j];
	}
}

- (void) removeDribbbleShots {
	NSLog(@"%s",__FUNCTION__);
	
	for(GWDribbbleShot * shotvc in self.shotViews) {
		[shotvc.view removeFromSuperview];
	}
	
	self.shotViews = [[NSMutableArray alloc] init];
}

- (void) populateDribbbleShots {
	NSLog(@"%s",__FUNCTION__);
	
	NSRect bounds = self.view.bounds;
	NSInteger w = 300;
	NSInteger h = 225;
	
	if(bounds.size.width < 1500) {
		w = 200;
		h = w*.75;
	}
	
	if(bounds.size.width < 300) {
		w = 40;
		h = 30;
	}
	
	NSInteger row = 0;
	NSInteger cols = ceilf(NSWidth(bounds)/w);
	NSInteger rows = ceilf(NSHeight(bounds)/h);
	NSInteger i = 0;
	NSInteger totalHeight = h*rows;
	NSInteger diffy = (totalHeight - NSHeight(bounds)) / 2;
	NSInteger totalWidth = w*cols;
	NSInteger diffx = (totalWidth - NSWidth(bounds)) / 2;
	NSRect f = NSMakeRect(-diffx,-diffy,w,h);
	
	//NSLog(@"bounds: %f %f",NSWidth(bounds),NSHeight(bounds));
	//NSLog(@"cell w/h: %li %li",w,h);
	//NSLog(@"first cell x/y: %f %f",f.origin.x,f.origin.y);
	
	for(NSDictionary * shot in self.shots) {
		GWDribbbleShot * sh = [[GWDribbbleShot alloc] initWithNibName:@"GWDribbbleShot" bundle:self.resourcesBundle];
		sh.view.frame = f;
		[self.view addSubview:sh.view];
		sh.representedObject = shot;
				
		f.origin.y += h;
		row++;
		if(row > rows) {
			f.origin.y = -diffy;
			f.origin.x += w;
			row = 0;
		}
		
		[self.shotViews addObject:sh];
		
		i++;
		if(i >= (rows*cols)+cols) {
			break;
		}
	}
}

- (IBAction) refresh:(id) sender {
	[self stopRefreshTimer];
	[self loadDribbble:nil];
	[self startRefreshTimer];
}

@end
