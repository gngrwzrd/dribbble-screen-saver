
#import "GWDataDiskCache.h"

@implementation GWDataDiskCache

+ (void) registerDefaults {
	NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
	NSMutableDictionary * registered = [NSMutableDictionary dictionary];
	[registered setObject:[NSNumber numberWithInteger:86400] forKey:@"oldestAllowableFileTimeDelta"];
	[defaults registerDefaults:registered];
}

- (id) init {
	self = [super init];
	[self setupDefaults];
	return self;
}

- (id) initWithDiskCacheURL:(NSURL *) url; {
	self = [self init];
	self.diskCacheURL = url;
	return self;
}

- (void) setupDefaults {
	[GWDataDiskCache registerDefaults];
	NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
	self.oldestAllowableFileTimeDelta = [[defaults objectForKey:@"oldestAllowableFileTimeDelta"] integerValue];
}

- (void) updateDefaults {
	NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
	[defaults setObject:[NSNumber numberWithInteger:_oldestAllowableFileTimeDelta] forKey:@"oldestAllowableFileTimeDelta"];
	[defaults synchronize];
}

- (void) setOldestAllowableFileTimeDelta:(NSTimeInterval)oldestAllowableFileTimeDelta {
	_oldestAllowableFileTimeDelta = oldestAllowableFileTimeDelta;
	[self updateDefaults];
}

- (void) setOldestAllowableFileTimeDeltaToDayCount:(NSInteger) dayCount; {
	self.oldestAllowableFileTimeDelta = 86400*dayCount;
}

- (CGFloat) oldestAllowableFileTimeDeltaInDays; {
	return _oldestAllowableFileTimeDelta / 86400;
}

- (void) createDiskCacheURL {
	NSFileManager * fileManager = [NSFileManager defaultManager];
	if(![fileManager fileExistsAtPath:self.diskCacheURL.path]) {
		[fileManager createDirectoryAtURL:self.diskCacheURL withIntermediateDirectories:TRUE attributes:nil error:nil];
	}
}

- (NSString *) localFileNameForURL:(NSURL *) url {
	if(!url) {
		return NULL;
	}
	NSString * path1 = [url absoluteString];
	NSString * path = (__bridge NSString *)CFURLCreateStringByReplacingPercentEscapesUsingEncoding(CFAllocatorGetDefault(),(CFStringRef)path1,NULL,kCFStringEncodingUTF8);
	//path = [path stringByRemovingPercentEncoding];
	path = [path stringByReplacingOccurrencesOfString:@"http://" withString:@""];
	path = [path stringByReplacingOccurrencesOfString:@"https://" withString:@""];
	path = [path stringByReplacingOccurrencesOfString:@":" withString:@"-"];
	path = [path stringByReplacingOccurrencesOfString:@"?" withString:@"-"];
	path = [path stringByReplacingOccurrencesOfString:@"/" withString:@"-"];
	path = [path stringByReplacingOccurrencesOfString:@" " withString:@"_"];
	return path;
}

- (NSURL *) localCachedURLForURL:(NSURL *) url; {
	if(!url) {
		return NULL;
	}
	NSString * fileName = [self localFileNameForURL:url];
	NSURL * localURL = [self.diskCacheURL URLByAppendingPathComponent:fileName];
	return localURL;
}

- (NSURL *) localCachedURLForRequest:(NSURLRequest *)request; {
	return [self localCachedURLForURL:request.URL];
}

- (NSURLRequest *) localRequestForRequest:(NSURLRequest *) request; {
	return [NSURLRequest requestWithURL:[self localCachedURLForRequest:request]];
}

- (NSData *) dataForRequest:(NSURLRequest *) request {
	if(!request || !request.URL) {
		return NULL;
	}
	NSString * fileName = [self localFileNameForURL:[request URL]];
	NSURL * localURL = [self.diskCacheURL URLByAppendingPathComponent:fileName];
	NSFileManager * fileManager = [NSFileManager defaultManager];
	if([fileManager fileExistsAtPath:localURL.path]) {
		return [NSData dataWithContentsOfURL:localURL];
	} else {
		if(self.logFilesNotCached) {
			NSLog(@"file not cached: %@",localURL);
		}
	}
	return nil;
}

- (NSData *) dataForURL:(NSURL *)url {
	if(!url) {
		return NULL;
	}
	NSString * fileName = [self localFileNameForURL:url];
	NSURL * localURL = [self.diskCacheURL URLByAppendingPathComponent:fileName];
	NSFileManager * fileManager = [NSFileManager defaultManager];
	if([fileManager fileExistsAtPath:localURL.path]) {
		return [NSData dataWithContentsOfURL:localURL];
	} else {
		if(self.logFilesNotCached) {
			NSLog(@"file not cached: %@",localURL);
		}
	}
	return nil;
}

- (BOOL) writeData:(NSData *)data forRequest:(NSURLRequest *)request {
	[self createDiskCacheURL];
	NSString * fileName = [self localFileNameForURL:[request URL]];
	NSURL * localURL = [self.diskCacheURL URLByAppendingPathComponent:fileName];
	return [data writeToURL:localURL atomically:TRUE];
}

- (BOOL) writeData:(NSData *) data forResponse:(NSURLResponse *) response {
	[self createDiskCacheURL];
	NSString * fileName = [self localFileNameForURL:[response URL]];
	NSURL * localURL = [self.diskCacheURL URLByAppendingPathComponent:fileName];
	return [data writeToURL:localURL atomically:TRUE];
}

- (BOOL) hasDataForRequest:(NSURLRequest *) request; {
	if(!request || !request.URL) {
		return FALSE;
	}
	[self createDiskCacheURL];
	NSFileManager * fileManager = [NSFileManager defaultManager];
	NSString * fileName = [self localFileNameForURL:[request URL]];
	NSURL * localURL = [self.diskCacheURL URLByAppendingPathComponent:fileName];
	return [fileManager fileExistsAtPath:localURL.path];
}

- (BOOL) hasDataForURL:(NSURL *) url; {
	if(!url) {
		return FALSE;
	}
	NSFileManager * fileManager = [NSFileManager defaultManager];
	NSString * fileName = [self localFileNameForURL:url];
	NSURL * localURL = [self.diskCacheURL URLByAppendingPathComponent:fileName];
	return [fileManager fileExistsAtPath:localURL.path];
}

- (void) clearOldFiles {
	NSFileManager * fileManager = [NSFileManager defaultManager];
	NSArray * files = [fileManager contentsOfDirectoryAtPath:self.diskCacheURL.path error:nil];
	NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
	NSTimeInterval cutoff = now-self.oldestAllowableFileTimeDelta;
	NSMutableArray * deleteThese = [NSMutableArray array];
	for(NSString * file in files) {
		NSURL * fullPath = [NSURL URLWithString:file relativeToURL:self.diskCacheURL];
		if(!fullPath) {
			continue;
		}
		NSDictionary * attributes = [fileManager attributesOfItemAtPath:fullPath.path error:nil];
		if(!attributes) {
			continue;
		}
		NSTimeInterval ca = [[attributes objectForKey:NSFileCreationDate] timeIntervalSince1970];
		if(ca < cutoff) {
			[deleteThese addObject:fullPath];
		}
	}
	
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND,0) , ^{
		NSError * __autoreleasing error = NULL;
		for(NSURL * fullPath in deleteThese) {
			[fileManager removeItemAtPath:fullPath.path error:&error];
			if(self.logFilesRemoved) {
				if(error) {
					NSLog(@"%@",error);
				} else {
					NSLog(@"removeing file: %@",fullPath.path);
				}
			}
		}
	});
}

- (void) empty {
	NSFileManager * fileManager = [NSFileManager defaultManager];
	[fileManager removeItemAtURL:self.diskCacheURL error:nil];
	[self createDiskCacheURL];
}

@end
