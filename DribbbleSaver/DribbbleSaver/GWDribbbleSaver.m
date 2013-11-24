
#import "GWDribbbleSaver.h"

static GWDribbbleSaver * _instance;

@interface GWDribbbleSaver ()
@end

@implementation GWDribbbleSaver

+ (GWDribbbleSaver *) instance {
	return _instance;
}

- (void) awakeFromNib {
	_instance = self;
	[self setup];
	[self setupDribbble];
	[self setupCache];
	[self decorate];
	[self loadDribbble];
}

- (void) setup {
	self.shots = [NSMutableArray array];
	self.shotViews = [NSMutableArray array];
}

- (void) setupDribbble {
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
	NSFileManager * fileManager = [NSFileManager defaultManager];
	NSURL * url = [fileManager URLForDirectory:NSApplicationSupportDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:TRUE error:nil];
	url = [url URLByAppendingPathComponent:@"HotShotsScreenSaver"];
	[fileManager createDirectoryAtPath:url.path withIntermediateDirectories:TRUE attributes:nil error:nil];
}

- (void) decorate {
	self.spinner.displayedWhenStopped = FALSE;
	self.spinner.color = [NSColor whiteColor];
	self.spinner.drawsBackground = FALSE;
}

- (void) setIsLoading:(BOOL)isLoading {
	_isLoading = isLoading;
	if(_isLoading) {
		[self.spinner startAnimation:nil];
	} else {
		[self.spinner stopAnimation:nil];
	}
}

- (void) loadDribbble {
	self.isLoading = TRUE;
	
	__block NSInteger loads = 3;
	__block NSInteger completed = 0;
	
	if(self.followingShots) {
		loads++;
		[self.followingShots loadPages:1 completion:^(DribbbleResponse *response) {
			[self.shots addObjectsFromArray:response.dribbble.shots];
			completed++;
			if(completed >= loads) {
				[self dribbbleLoaded];
			}
		}];
	}
	
	[self.everyone loadPages:1 completion:^(DribbbleResponse *response) {
		[self.shots addObjectsFromArray:response.dribbble.shots];
		completed++;
		if(completed >= loads) {
			[self dribbbleLoaded];
		}
	}];
	
	[self.debut loadPages:1 completion:^(DribbbleResponse *response) {
		[self.shots addObjectsFromArray:response.dribbble.shots];
		completed++;
		if(completed >= loads) {
			[self dribbbleLoaded];
		}
	}];
	
	[self.popular loadPages:1 completion:^(DribbbleResponse *response) {
		[self.shots addObjectsFromArray:response.dribbble.shots];
		completed++;
		if(completed >= loads) {
			[self dribbbleLoaded];
		}
	}];
}

- (void) refreshDribbble:(NSTimer *) timer {
	[self stopSwitchTimer];
	
	self.shots = [NSMutableArray array];
	self.isLoading = TRUE;
	
	__block NSInteger loads = 3;
	__block NSInteger completed = 0;
	
	[self.everyone loadPages:2 completion:^(DribbbleResponse *response) {
		[self.shots addObjectsFromArray:response.dribbble.shots];
		completed++;
		if(completed >= loads) {
			[self dribbbleRefreshed];
		}
	}];
	
	[self.debut loadPages:2 completion:^(DribbbleResponse *response) {
		[self.shots addObjectsFromArray:response.dribbble.shots];
		completed++;
		if(completed >= loads) {
			[self dribbbleRefreshed];
		}
	}];
	
	[self.popular loadPages:2 completion:^(DribbbleResponse *response) {
		[self.shots addObjectsFromArray:response.dribbble.shots];
		completed++;
		if(completed >= loads) {
			[self dribbbleRefreshed];
		}
	}];
}

- (void) dribbbleLoaded {
	self.isLoading = FALSE;
	[self shuffleShots];
	[self populateDribbbleShots];
	[self startTimer];
	[NSTimer scheduledTimerWithTimeInterval:10 target:self selector:@selector(startSwitchTimer) userInfo:nil repeats:FALSE];
}

- (void) dribbbleRefreshed {
	self.isLoading = FALSE;
	[self shuffleShots];
	[self startSwitchTimer];
}

- (void) shuffleShots {
	[self.shots sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
		NSInteger ri = arc4random_uniform(100);
		if(ri > 50) {
			return -1;
		} else {
			return 1;
		}
	}];
}

- (void) startTimer {
	refreshTimer = [NSTimer scheduledTimerWithTimeInterval:120 target:self selector:@selector(refreshDribbble:) userInfo:nil repeats:TRUE];
}

- (void) stopTimer {
	[refreshTimer invalidate];
	refreshTimer = nil;
}

- (void) startSwitchTimer {
	switchTimer = [NSTimer scheduledTimerWithTimeInterval:2.75 target:self selector:@selector(switchDribbble:) userInfo:nil repeats:TRUE];
	switchTimer2 = [NSTimer scheduledTimerWithTimeInterval:3.8 target:self selector:@selector(switchDribbble:) userInfo:nil repeats:TRUE];
}

- (void) stopSwitchTimer {
	[switchTimer invalidate];
	switchTimer = nil;
	
	[switchTimer2 invalidate];
	switchTimer2 = nil;
}

- (void) switchDribbble:(NSTimer *) timer {
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

- (void) populateDribbbleShots {
	NSRect bounds = self.view.bounds;
	NSInteger w = 300;
	NSInteger h = 225;
	
	if(bounds.size.width < 1500) {
		w = 200;
		h = w*.75;
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
	
	for(NSDictionary * shot in self.shots) {
		GWDribbbleShot * sh = [[GWDribbbleShot alloc] initWithNibName:@"GWDribbbleShot" bundle:self.resourcesBundle];
		sh.representedObject = shot;
		sh.view.frame = f;
		[self.view addSubview:sh.view];
		
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
	[self refreshDribbble:nil];
	[self stopTimer];
	[self startTimer];
}

@end
