
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
	_instance = self;
	[self checkOldVersion];
	[self setup];
	[self setupDribbble];
	[self setupCache];
	[self deserializeShots];
}

- (void) viewDidLoad {
	[self checkOldVersion];
}

- (void) checkOldVersion {
	NSString * bundleVersion = [[self.resourcesBundle infoDictionary] objectForKey:@"CFBundleVersion"];
	if([bundleVersion isEqualToString:@"7"]) {
		NSFileManager * fileManager = [NSFileManager defaultManager];
		NSURL * url = [fileManager URLForDirectory:NSApplicationSupportDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:TRUE error:nil];
		url = [url URLByAppendingPathComponent:@"HotShotsScreenSaver"];
		[fileManager removeItemAtURL:url error:nil];
	}
}

- (void) setup {
	self.shots = [NSMutableArray array];
	self.shotViews = [NSMutableArray array];
}

- (void) setupDribbble {
	self.latest = [[Dribbble alloc] init];
	self.popular = [[Dribbble alloc] init];
	
	[self.popular setAccessToken:@"98df103682952ae0f48aaaa044478f11b66f1fe1bdcc04245b9870a85f65c64b"];
	[self.latest setAccessToken:@"98df103682952ae0f48aaaa044478f11b66f1fe1bdcc04245b9870a85f65c64b"];
	
	NSString * tokenPath = [@"~/Library/Application Support/DribbbleScreenSaver/accesstoken.txt" stringByExpandingTildeInPath];
	if([[NSFileManager defaultManager] fileExistsAtPath:tokenPath]) {
		NSData * data = [NSData dataWithContentsOfFile:tokenPath];
		NSString * token = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
		self.popular.accessToken = token;
		self.latest.accessToken = token;
	}
}

- (void) setupCache {
#if GWDribbbleSaverUseCache
	NSURL * as = [GWDribbbleSaver applicationSupport];
	NSURL * url = [as URLByAppendingPathComponent:@"HotShotsScreenSaver"];
	self.cache = [[GWDataDiskCache alloc] initWithDiskCacheURL:url];
	self.cache.oldestAllowableFileTimeDelta = 86400;
	[self.cache clearOldFiles];
#endif
}

- (void) run {
	if(self.shots.count > 0) {
		[self shuffleShots];
		if([self canUseCachedShots]) {
			_useCachedShots = TRUE;
			[self populateDribbbleShotsFromCachedImages];
		} else {
			[self populateDribbbleShots];
		}
		[self startRefreshTimer];
		[self startSwitchTimer];
	}
	[self loadDribbble:nil];
}

- (void) serializeShots {
	NSURL * as = [GWDribbbleSaver applicationSupport];
	NSURL * shots = [as URLByAppendingPathComponent:@"shots.data"];
	NSData * data = [NSKeyedArchiver archivedDataWithRootObject:self.shots];
	[data writeToURL:shots atomically:TRUE];
}

- (void) deserializeShots {
	NSURL * as = [GWDribbbleSaver applicationSupport];
	NSURL * shots = [as URLByAppendingPathComponent:@"shots.data"];
	NSFileManager * fileManager = [NSFileManager defaultManager];
	NSDictionary * stats = [fileManager attributesOfItemAtPath:shots.path error:nil];
	NSString * size = [stats objectForKey:NSFileSize];
	if([size integerValue]/1000000 <= 2) {
		if([fileManager fileExistsAtPath:shots.path]) {
			NSData * data = [NSData dataWithContentsOfURL:shots];
			_shots = [NSKeyedUnarchiver unarchiveObjectWithData:data];
		}
	}
}

- (void) loadDribbble:(id) sender {
	__block int loadCount = 0;
	__block NSMutableArray * newShots = [NSMutableArray array];
	
	[self.latest listShotsWithParameters:@{@"sort":@"recent",@"per_page":@"100"} completion:^(DribbbleResponse *response) {
		[newShots addObjectsFromArray:response.data];
		loadCount++;
		if(loadCount == 2) {
			[self dribbbleLoadedNewShots:newShots];
		}
	}];
	
	[self.popular listShotsWithParameters:@{@"per_page":@"100"} completion:^(DribbbleResponse *response) {
		[newShots addObjectsFromArray:response.data];
		loadCount++;
		if(loadCount == 2) {
			[self dribbbleLoadedNewShots:newShots];
		}
	}];
}

- (void) dribbbleLoadedNewShots:(NSMutableArray *) array {
	_useCachedShots = FALSE;
	self.shots = array;
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

- (void) startRefreshTimer {
	[refreshTimer invalidate];
	refreshTimer = [NSTimer scheduledTimerWithTimeInterval:300 target:self selector:@selector(loadDribbble:) userInfo:nil repeats:TRUE];
}

- (void) stopRefreshTimer {
	[refreshTimer invalidate];
	refreshTimer = nil;
}

- (void) startSwitchTimer {
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
	[switchTimer invalidate];
	switchTimer = nil;
	
	[switchTimer2 invalidate];
	switchTimer2 = nil;
}

- (void) startTimers {
	[self stopTimers];
	[self startSwitchTimer];
	[self startRefreshTimer];
}

- (void) stopTimers {
	[self stopRefreshTimer];
	[self stopSwitchTimer];
}

- (BOOL) canUseCachedShots {
	NSFileManager * fileManager = [NSFileManager defaultManager];
	NSArray * fls = [fileManager contentsOfDirectoryAtURL:self.cache.diskCacheURL includingPropertiesForKeys:nil options:0 error:nil];
	return fls.count > 50;
}

- (void) switchDribbble:(NSTimer *) timer {
	if(self.shotViews.count < 1) {
		return;
	}
	
	NSInteger switchCount = 1;
	NSMutableArray * __shots = [NSMutableArray array];
	NSInteger ri = 0;
	
	if(_useCachedShots) {
		//NSLog(@"switching to cached shot!");
		NSFileManager * fileManager = [NSFileManager defaultManager];
		NSArray * files = [fileManager contentsOfDirectoryAtPath:self.cache.diskCacheURL.path error:nil];
		NSMutableDictionary * shot = NULL;
		for(NSInteger i = 0; i < switchCount; i++) {
			shot = [NSMutableDictionary dictionary];
			ri = arc4random_uniform((uint32_t)files.count);
			[shot setObject:[files objectAtIndex:ri] forKey:@"cache_shot_filename"];
			[__shots addObject:shot];
		}
	} else {
		for(NSInteger i = 0; i < switchCount; i++) {
			ri = arc4random_uniform((uint32_t)self.shots.count);
			[__shots addObject:[self.shots objectAtIndex:ri]];
		}
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
	for(GWDribbbleShot * shotvc in self.shotViews) {
		[shotvc.view removeFromSuperview];
	}
	self.shotViews = [[NSMutableArray alloc] init];
}

- (void) populateDribbbleShots {
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

- (void) populateDribbbleShotsFromCachedImages {
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
	
	GWDribbbleSaver * saver = [GWDribbbleSaver instance];
	NSFileManager * fileManager = [NSFileManager defaultManager];
	NSMutableArray * files = [NSMutableArray arrayWithArray:[fileManager contentsOfDirectoryAtPath:saver.cache.diskCacheURL.path error:nil]];
	
	[files sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
		NSInteger ri = arc4random_uniform(100);
		if(ri > 50) {
			return -1;
		} else {
			return 1;
		}
	}];
	
	NSMutableDictionary * shot = NULL;
	for(NSString * file in files) {
		shot = [NSMutableDictionary dictionary];
		[shot setObject:file forKey:@"cache_shot_filename"];
		
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
