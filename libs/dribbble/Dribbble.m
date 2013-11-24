
#import "Dribbble.h"

//=== Dribbble
#pragma mark Dribbble

@interface Dribbble ()
+ (NSURLRequest *) ApiURLWithPath:(NSString *) path options:(NSDictionary *) options;
+ (DribbbleResponse *) sendSynchronousRequest:(NSURLRequest *) request;
+ (DribbbleResponse *) sendRequest:(NSURLRequest *) request options:(NSDictionary *) options completion:(DribbbleCompletionBlock)completion;
+ (void) sendAsynchRequest:(NSURLRequest *) request completion:(DribbbleCompletionBlock)completion;
- (NSDictionary *) _getDefaultAPIOptions;
- (void) _asyncPagerFinished:(DribbbleResponse *) completion completion:(DribbbleCompletionBlock) pagerCompletion;
- (DribbbleResponse *) _sendSynchronousePagerRequest;
- (void) _sendAsynchronousPagerRequest:(DribbbleCompletionBlock) completion;
- (DribbbleResponse *) _load:(DribbbleCompletionBlock) completion;
- (void) _addToShots:(NSDictionary *) jsonData;
@end

@interface DribbbleResponse ()
+ (DribbbleResponse *) responseWithData:(NSData *)data;
+ (DribbbleResponse *) responseWithError:(NSError *)error;
@end

@implementation Dribbble

+ (NSURLRequest *) ApiURLWithPath:(NSString *) path options:(NSDictionary *) options; {
	NSString * request = [NSString stringWithFormat:@"http://api.dribbble.com%@",path];
	if(options.count) {
		request = [[request stringByAppendingString:@"?page="] stringByAppendingString:[options objectForKey:@"page"]];
		request = [[request stringByAppendingString:@"&per_page="] stringByAppendingString:[options objectForKey:@"per_page"]];
	}
	NSURL * url = [NSURL URLWithString:request];
	NSURLRequest * req = [NSURLRequest requestWithURL:url];
	return req;
}

+ (DribbbleResponse *) sendSynchronousRequest:(NSURLRequest *) request {
	NSURLResponse * __autoreleasing response;
	NSError * __autoreleasing error;
	NSData * data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
	DribbbleResponse * dresponse = NULL;
	if(error) {
		dresponse = [DribbbleResponse responseWithError:error];
		dresponse.connectionResponse = response;
	} else {
		dresponse = [DribbbleResponse responseWithData:data];
	}
	return dresponse;
}

+ (void) sendAsynchRequest:(NSURLRequest *) request completion:(DribbbleCompletionBlock)completion {
	[NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse * response, NSData * data, NSError * error) {
		if(error) {
			DribbbleResponse * response = [DribbbleResponse responseWithError:error];
			completion(response);
			return;
		}
		if(data) {
			DribbbleResponse * response = [DribbbleResponse responseWithData:data];
			completion(response);
		}
	}];
}

+ (DribbbleResponse *) sendRequest:(NSURLRequest *) request options:(NSDictionary *) options completion:(DribbbleCompletionBlock)completion; {
	if(!completion) {
		return [self sendSynchronousRequest:request];
	}
	[self sendAsynchRequest:request completion:completion];
	return nil;
}

+ (DribbbleResponse *) everyoneShotsWithOptions:(NSDictionary *)options completion:(DribbbleCompletionBlock)completion; {
	NSURLRequest * request = [Dribbble ApiURLWithPath:@"/shots/everyone" options:options];
	return [Dribbble sendRequest:request options:options completion:completion];
}

+ (DribbbleResponse *) popularShotsWithOptions:(NSDictionary *)options completion:(DribbbleCompletionBlock)completion; {
	NSURLRequest * request = [Dribbble ApiURLWithPath:@"/shots/popular" options:options];
	return [Dribbble sendRequest:request options:options completion:completion];
}

+ (DribbbleResponse *) debutShotsWithOptions:(NSDictionary *)options completion:(DribbbleCompletionBlock)completion; {
	NSURLRequest * request = [Dribbble ApiURLWithPath:@"/shots/debuts" options:options];
	return [Dribbble sendRequest:request options:options completion:completion];
}

+ (DribbbleResponse *) commentsForShotId:(NSString *)sid options:(NSDictionary *)options completion:(DribbbleCompletionBlock)completion; {
	NSURLRequest * request = [Dribbble ApiURLWithPath:[NSString stringWithFormat:@"/shots/%@/comments",sid] options:options];
	if(!completion) {
		DribbbleResponse * response = [self sendSynchronousRequest:request];
		if(response.error) {
			return response;
		}
		response.jsonData = [response.jsonData objectForKey:@"comments"];
		return response;
	}
	return [Dribbble sendRequest:request options:options completion:^(DribbbleResponse *response) {
		if(response.error) {
			completion(response);
		} else {
			response.jsonData = [response.jsonData objectForKey:@"comments"];
			completion(response);
		}
	}];
}

+ (DribbbleResponse *) shotWithId:(NSString *)sid options:(NSDictionary *)options completion:(DribbbleCompletionBlock)completion; {
	NSURLRequest * request = [Dribbble ApiURLWithPath:[NSString stringWithFormat:@"/shots/%@",sid] options:options];
	return [Dribbble sendRequest:request options:options completion:completion];
}

+ (DribbbleResponse *) playerShots:(NSString *) player option:(NSDictionary *)options completion:(DribbbleCompletionBlock)completion; {
	NSURLRequest * request = [Dribbble ApiURLWithPath:[NSString stringWithFormat:@"/players/%@/shots",player] options:options];
	return [Dribbble sendRequest:request options:options completion:completion];
}

+ (DribbbleResponse *) followedPlayerShotsForPlayer:(NSString *) player option:(NSDictionary *)options completion:(DribbbleCompletionBlock)completion; {
	NSURLRequest * request = [Dribbble ApiURLWithPath:[NSString stringWithFormat:@"/players/%@/shots/following",player] options:options];
	return [Dribbble sendRequest:request options:options completion:completion];
}

+ (DribbbleResponse *) likesForPlayer:(NSString *) player option:(NSDictionary *)options completion:(DribbbleCompletionBlock)completion; {
	NSURLRequest * request = [Dribbble ApiURLWithPath:[NSString stringWithFormat:@"/players/%@/shots/likes",player] options:options];
	return [Dribbble sendRequest:request options:options completion:completion];
}

+ (DribbbleResponse *) followers:(NSString *) player option:(NSDictionary *)options completion:(DribbbleCompletionBlock)completion; {
	NSURLRequest * request = [Dribbble ApiURLWithPath:[NSString stringWithFormat:@"/players/%@/followers",player] options:options];
	return [Dribbble sendRequest:request options:options completion:completion];
}

+ (DribbbleResponse *) following:(NSString *) player option:(NSDictionary *)options completion:(DribbbleCompletionBlock)completion; {
	NSURLRequest * request = [Dribbble ApiURLWithPath:[NSString stringWithFormat:@"/players/%@/following",player] options:options];
	return [Dribbble sendRequest:request options:options completion:completion];
}

+ (DribbbleResponse *) playerDraftees:(NSString *) player option:(NSDictionary *)options completion:(DribbbleCompletionBlock)completion; {
	NSURLRequest * request = [Dribbble ApiURLWithPath:[NSString stringWithFormat:@"/players/%@/draftees",player] options:options];
	return [Dribbble sendRequest:request options:options completion:completion];
}

+ (DribbbleResponse *) player:(NSString *)player options:(NSDictionary *)options completion:(DribbbleCompletionBlock)completion; {
	NSURLRequest * request = [Dribbble ApiURLWithPath:[NSString stringWithFormat:@"/players/%@",player] options:options];
	return [Dribbble sendRequest:request options:options completion:completion];
}

+ (Dribbble *) deserializedPagerInstanceAtURL:(NSURL *) url {
	NSFileManager * fileManager = [NSFileManager defaultManager];
	Dribbble * dribbble = NULL;
	if([fileManager fileExistsAtPath:url.path]) {
		NSData * data = [NSData dataWithContentsOfFile:url.path];
		dribbble = [NSKeyedUnarchiver unarchiveObjectWithData:data];
	}
	return dribbble;
}

- (id) init {
	self = [super init];
	_mutableShots = [[NSMutableArray alloc] init];
	_shotsMerger = [[DribbbleShotsMergerDefault alloc] init];
	_currentPage = 0;
	self.perPage = 50;
	return self;
}

- (id) initWithType:(DribbblePagerType) type playerName:(NSString *) playerName {
	self = [super init];
	_pagerType = type;
	if(_pagerType == DribbblePagerTypeFollowedPlayerShots && ![playerName isEqualToString:@""]) {
		_playerName = playerName;
	}
	return self;
}

- (Dribbble *) initEveryonePager; {
	self = [self init];
	_pagerType = DribbblePagerTypeEveryone;
	return self;
}

- (Dribbble *) initPopularPager; {
	self = [self init];
	_pagerType = DribbblePagerTypePopular;
	return self;
}

- (Dribbble *) initDebutPager; {
	self = [self init];
	_pagerType = DribbblePagerTypeDebut;
	return self;
}

- (Dribbble *) initFollowedPlayerShotsPager:(NSString *) playerName; {
	self = [self init];
	_pagerType = DribbblePagerTypeFollowedPlayerShots;
	_playerName = playerName;
	if(!playerName || [playerName isEqualToString:@""]) {
		NSException * ex = [NSException exceptionWithName:@"NilValue" reason:@"[Dribbble initFollowingShotsPager:] -> playerName cannot be nil." userInfo:nil];
		NSLog(@"%@",ex);
		@throw ex;
	}
	return self;
}

- (id) initWithCoder:(NSCoder *)aDecoder; {
	self = [super init];
	NSKeyedUnarchiver * unarchiver = (NSKeyedUnarchiver *)aDecoder;
	_mutableShots = [NSMutableArray arrayWithArray:[unarchiver decodeObjectForKey:@"shots"]];
	_pagerType = [unarchiver decodeIntForKey:@"pagerType"];
	_playerName = [unarchiver decodeObjectForKey:@"playerName"];
	_minShotsCount = [unarchiver decodeIntegerForKey:@"minShotsCount"];
	_perPage = [unarchiver decodeIntegerForKey:@"perPage"];
	return self;
}

- (void) encodeWithCoder:(NSCoder *)aCoder; {
	NSKeyedArchiver * archiver = (NSKeyedArchiver *)aCoder;
	[archiver encodeInt:_pagerType forKey:@"pagerType"];
	[archiver encodeInteger:_perPage forKey:@"perPage"];
	[archiver encodeInteger:_minShotsCount forKey:@"minShotsCount"];
	[archiver encodeObject:_playerName forKey:@"playerName"];
	[archiver encodeObject:_mutableShots forKey:@"shots"];
}

- (void) _addToShots:(NSDictionary *) jsonData; {
	NSMutableArray * freshShots = [jsonData objectForKey:@"shots"];
	[_freshShots addObjectsFromArray:freshShots];
}

- (void) _mergeFreshShots {
	[self.shotsMerger mergeFreshShots:_freshShots intoExistingShots:_mutableShots];
}

- (NSArray *) shots {
	return [NSArray arrayWithArray:_mutableShots];
}

- (NSDictionary *) _getDefaultAPIOptions {
	NSMutableDictionary * options = [NSMutableDictionary dictionary];
	[options setObject:[NSString stringWithFormat:@"%li",(long)_currentPage] forKey:@"page"];
	[options setObject:[NSString stringWithFormat:@"%li",(long)self.perPage] forKey:@"per_page"];
	return options;
}

- (DribbbleResponse *) _sendSynchronousePagerRequest {
	DribbbleResponse * result = [[DribbbleResponse alloc] init];
	result.dribbble = self;
	while(_pagesToLoad > 0) {
		_pagesToLoad--;
		NSDictionary * o = [self _getDefaultAPIOptions];
		DribbbleResponse * res = NULL;
		switch(_pagerType) {
			case DribbblePagerTypeEveryone: {
				res = [Dribbble everyoneShotsWithOptions:o completion:NULL];
				break;
			}
			case DribbblePagerTypeDebut: {
				res = [Dribbble debutShotsWithOptions:o completion:NULL];
				break;
			}
			case DribbblePagerTypeFollowedPlayerShots: {
				res = [Dribbble followedPlayerShotsForPlayer:_playerName option:o completion:NULL];
				break;
			}
			case DribbblePagerTypePopular: {
				res = [Dribbble popularShotsWithOptions:o completion:NULL];
				break;
			}
			default: {
				NSException * ex = [NSException exceptionWithName:@"PagerTypeUnknown" reason:@"Dribbble.pagerType is not a valid pager type." userInfo:nil];
				@throw ex;
				break;
			}
		}
		
		if(res.error) {
			_currentPage = 0;
			_loading = FALSE;
			result.error = res.error;
			result.connectionResponse = result.connectionResponse;
			break;
		} else {
			[self _addToShots:res.jsonData];
			_currentPage++;
		}
	}
	
	_loading = FALSE;
	[self _mergeFreshShots];
	return result;
}

- (void) _sendAsynchronousPagerRequest:(DribbbleCompletionBlock) completion; {
	NSDictionary * options = [self _getDefaultAPIOptions];
	switch (_pagerType) {
		case DribbblePagerTypeEveryone: {
			[Dribbble everyoneShotsWithOptions:options completion:^(DribbbleResponse *response) {
				[self _asyncPagerFinished:response completion:completion];
			}];
			break;
		}
		case DribbblePagerTypeDebut: {
			[Dribbble debutShotsWithOptions:options completion:^(DribbbleResponse *response) {
				[self _asyncPagerFinished:response completion:completion];
			}];
			break;
		}
		case DribbblePagerTypePopular: {
			[Dribbble popularShotsWithOptions:options completion:^(DribbbleResponse *response) {
				[self _asyncPagerFinished:response completion:completion];
			}];
			break;
		}
		case DribbblePagerTypeFollowedPlayerShots: {
			[Dribbble followedPlayerShotsForPlayer:_playerName option:options completion:^(DribbbleResponse *response) {
				[self _asyncPagerFinished:response completion:completion];
			}];
			break;
		}
		default: {
			NSException * ex = [NSException exceptionWithName:@"PagerTypeUnknown" reason:@"Dribbble.pagerType is not a valid pager type." userInfo:nil];
			@throw ex;
			break;
		}
	}
}

- (void) _asyncPagerFinished:(DribbbleResponse *) completion completion:(DribbbleCompletionBlock) pagerCompletion; {
	DribbbleResponse * response = [[DribbbleResponse alloc] init];
	response.dribbble = self;
	
	if(completion.error) {
		_loading = FALSE;
		response.error = completion.error;
		response.connectionResponse = completion.connectionResponse;
		pagerCompletion(response);
		return;
	}
	
	NSMutableArray * shots = [completion.jsonData objectForKey:@"shots"];
	NSInteger shotsCount = shots.count;
	
	_pagesToLoad--;
	
	if(shots.count > 0) {
		[self _addToShots:completion.jsonData];
		if(_pagesToLoad > 0 && shotsCount >= self.perPage) {
			[self _load:pagerCompletion];
		} else {
			_loading = FALSE;
			[self _mergeFreshShots];
			pagerCompletion(response);
		}
	} else {
		_loading = FALSE;
		[self _mergeFreshShots];
		pagerCompletion(response);
	}
}

- (DribbbleResponse *) _load:(DribbbleCompletionBlock) completion {
	_loading = TRUE;
	_currentPage++;
	if(completion) {
		[self _sendAsynchronousPagerRequest:completion];
	} else {
		return [self _sendSynchronousePagerRequest];
	}
	DribbbleResponse * response = [[DribbbleResponse alloc] init];
	response.dribbble = self;
	return response;
}

- (DribbbleResponse *) load:(DribbbleCompletionBlock) completion; {
	if(_loading) {
		return NULL;
	}
	_currentPage = 0;
	_freshShots = [[NSMutableArray alloc] init];
	[self.shotsMerger dribbbleShotsWillLoad:self];
	return [self _load:completion];
}

- (DribbbleResponse *) loadPages:(NSInteger) pageCount completion:(DribbbleCompletionBlock) completion; {
	if(_loading) {
		return NULL;
	}
	_pagesToLoad = pageCount;
	_currentPage = 0;
	_freshShots = [[NSMutableArray alloc] init];
	[self.shotsMerger dribbbleShotsWillLoad:self];
	return [self _load:completion];
}

- (DribbbleResponse *) loadPage:(NSInteger) page completion:(DribbbleCompletionBlock) completion; {
	if(_loading) {
		return NULL;
	}
	NSInteger realPage = page;
	if(page == -1) {
		realPage = (NSInteger) ceilf((float)_mutableShots.count/self.perPage);
	}
	_pagesToLoad = 1;
	_currentPage = realPage;
	_freshShots = [[NSMutableArray alloc] init];
	[self.shotsMerger dribbbleShotsWillLoad:self];
	return [self _load:completion];
}

- (BOOL) writeDataToURL:(NSURL *)url atomically:(BOOL)atomically {
	NSData * data = [NSKeyedArchiver archivedDataWithRootObject:self];
	return [data writeToURL:url atomically:atomically];
}

- (BOOL) writeDataToSerializationURLAtomically:(BOOL)atomically {
	return [self writeDataToURL:self.serializationURL atomically:atomically];
}

@end


//===DribbbleShotsMerger
#pragma mark DribbbleShotsMerger

@implementation DribbbleShotsMergerDefault

- (void) mergeFreshShots:(NSMutableArray *)freshShots intoExistingShots:(NSMutableArray *)existingShots {
	if(freshShots.count < 1) {
		return;
	}
	
	if(existingShots.count < 1) {
		[existingShots addObjectsFromArray:freshShots];
		_mergedShots = [NSArray arrayWithArray:freshShots];
	} else {
		NSMutableArray * toInsert = [[NSMutableArray alloc] init];
		NSDictionary * shot = NULL;
		
		for(shot in freshShots) {
			BOOL insert = TRUE;
			NSInteger sid = [[shot objectForKey:@"id"] integerValue];
			NSDictionary * mshot = NULL;
			
			for(mshot in existingShots) {
				NSInteger mshotid = [[mshot objectForKey:@"id"] integerValue];
				if(sid == mshotid) {
					insert = FALSE;
					break;
				}
			}
			
			if(insert) {
				[toInsert addObject:shot];
			}
		}
		
		if(toInsert.count > 0) {
			//NSRange range = NSMakeRange((existingShots.count-1)-toInsert.count,toInsert.count);
			//if(toInsert.count == existingShots.count) {
			//	range = NSMakeRange(0,toInsert.count);
			//}
			//[existingShots removeObjectsInRange:range];
			[existingShots insertObjects:toInsert atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0,toInsert.count)]];
			_mergedShots = [NSArray arrayWithArray:toInsert];
		}
	}
}

- (NSArray *) mergedShots {
	return _mergedShots;
}

- (void) dribbbleShotsWillLoad:(Dribbble *)dribbble {
	_mergedShots = [NSArray array];
}

- (void) reset {
	_mergedShots = [NSArray array];
}

@end


//=== DribbbleResponse
#pragma mark DribbbleResponse

@implementation DribbbleResponse

+ (DribbbleResponse *) responseWithData:(NSData *)data {
	DribbbleResponse * response = [[DribbbleResponse alloc] init];
	NSError * __autoreleasing jsonError;
	NSJSONReadingOptions jsonOptions = NSJSONReadingMutableContainers|NSJSONReadingMutableLeaves;
	id json = [NSJSONSerialization JSONObjectWithData:data options:jsonOptions error:&jsonError];
	if(jsonError) {
		response.error = jsonError;
	} else {
		response.jsonData = json;
	}
	return response;
}

+ (DribbbleResponse *) responseWithError:(NSError *)error {
	DribbbleResponse * response = [[DribbbleResponse alloc] init];
	response.error = error;
	return response;
}

- (NSString *) description {
	if(self.dribbble && !self.error && !self.connectionResponse) {
		return [self.dribbble.shots description];
	}
	if(self.jsonData) {
		return [self.jsonData description];
	}
	if(self.error) {
		return [self.error description];
	}
	if(self.connectionResponse) {
		return [self.connectionResponse description];
	}
	return [NSString stringWithFormat:@"[DribbbleResponse <%p>]",self];
}

@end
