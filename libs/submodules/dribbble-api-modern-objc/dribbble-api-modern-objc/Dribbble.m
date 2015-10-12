
#import "Dribbble.h"
#import "URLParser.h"

NSString * const DribbbleErrorDomain = @"DribbbleErrorDomain";
NSString * const DribbbleScopePublic = @"public";
NSString * const DribbbleScopeWrite = @"write";
NSString * const DribbbleScopeComment = @"comment";
NSString * const DribbbleScopeUpload = @"upload";
NSInteger const DribbbleErrorCodeBadCredentials = 10;

@interface Dribbble ()
@property (copy) DribbbleCompletionBlock authorizeCompletion;
@end

#pragma mark Dribbble
@implementation Dribbble

#pragma mark utilities

- (id) init {
	self = [super init];
	NSURLSessionConfiguration * config = [NSURLSessionConfiguration defaultSessionConfiguration];
	self.defaultSession = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:[NSOperationQueue mainQueue]];
	return self;
}

- (void) __appendDictionaryOfParameters:(NSDictionary * ) dictionary toString:(NSMutableString *) string {
	if(!dictionary) {
		return;
	}
	NSUInteger i = 0;
	for(NSString * key in dictionary) {
		if(i == 0) {
			[string appendFormat:@"?%@=%@",key,[dictionary objectForKey:key]];
		} else {
			[string appendFormat:@"&%@=%@",key,[dictionary objectForKey:key]];
		}
		i++;
	}
}

- (NSDictionary *) __getParamsWithAccessToken:(NSDictionary *) otherParameters {
	NSMutableDictionary * pams = [NSMutableDictionary dictionaryWithDictionary:otherParameters];
	[pams setObject:self.accessToken forKey:@"access_token"];
	return pams;
}

- (void) __handleExpectingJSONResponse:(NSURLResponse *) response data:(NSData *) data error:(NSError *) error completion:(DribbbleCompletionBlock) completion {
	NSObject * json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
	DribbbleResponse * dresponse = [[DribbbleResponse alloc] init];
	if(error) {
		dresponse.error = error;
	} else if([json isKindOfClass:[NSArray class]]) {
		dresponse.data = json;
	} else if([json isKindOfClass:[NSDictionary class]]) {
		__weak NSDictionary * jsondict = (NSDictionary *)json;
		NSString * message = [jsondict objectForKey:@"message"];
		if(message) {
			NSInteger code = 0;
			if([message isEqualToString:@"Bad credentials."]) {
				code = DribbbleErrorCodeBadCredentials;
			}
			NSError * error = [NSError errorWithDomain:DribbbleErrorDomain code:code userInfo:jsondict];
			dresponse.error = error;
		} else {
			dresponse.data = json;
		}
	}
	completion(dresponse);
}

- (void) __handleExpectingEmptyResponse:(NSURLResponse *) response data:(NSData *) data error:(NSError *) error completion:(DribbbleCompletionBlock) completion; {
	DribbbleResponse * dresponse = [[DribbbleResponse alloc] init];
	if(error) {
		dresponse.error = error;
	} else if(data.length > 0) {
		NSObject * json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
		__weak NSDictionary * jsondict = (NSDictionary *)json;
		NSString * message = [jsondict objectForKey:@"message"];
		if(message) {
			NSInteger code = 0;
			if([message isEqualToString:@"Bad credentials."]) {
				code = DribbbleErrorCodeBadCredentials;
			}
			NSError * error = [NSError errorWithDomain:DribbbleErrorDomain code:code userInfo:jsondict];
			dresponse.error = error;
		}
	}
	completion(dresponse);
}

- (NSMutableURLRequest *) __requestWithAPIEndpoint:(NSString *) apiEndpoint method:(NSString *) method params:(NSDictionary *) params {
	NSMutableString * u = [NSMutableString stringWithString:apiEndpoint];
	NSDictionary * pams = [self __getParamsWithAccessToken:params];
	[self __appendDictionaryOfParameters:pams toString:u];
	NSURL * url = [NSURL URLWithString:u];
	NSMutableURLRequest * request = [[NSMutableURLRequest alloc] initWithURL:url];
	if(method) {
		request.HTTPMethod = method;
	}
	return request;
}

#pragma mark auth

- (void) authorizeWithScopes:(NSArray *) scopes completion:(DribbbleCompletionBlock) completion; {
	self.authorizeCompletion = completion;
	NSString * u = [NSString stringWithFormat:@"https://dribbble.com/oauth/authorize?client_id=%@",self.clientId];
	NSMutableString * ms = [NSMutableString stringWithString:u];
	if(scopes && scopes.count > 0) {
		[ms appendFormat:@"&scope="];
		for (NSString * scope in scopes) {
			[ms appendFormat:@"%@+",scope];
		}
	}
	NSURL * url = [NSURL URLWithString:ms];
	[[NSWorkspace sharedWorkspace] openURL:url];
}

- (void) handleCustomSchemeCallback:(NSString *) url; {
	URLParser * parser = [[URLParser alloc] initWithURLString:url];
	NSString * code = [parser valueForVariable:@"code"];
	
	NSURL * token = [NSURL URLWithString:@"https://dribbble.com/oauth/token"];
	NSMutableString * u = [NSMutableString stringWithString:@"https://dribbble.com/oauth/token?"];
	[u appendFormat:@"code=%@",code];
	[u appendFormat:@"&client_id=%@",self.clientId];
	[u appendFormat:@"&client_secret=%@",self.clientSecret];
	
	NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:token];
	NSDictionary * params = @{@"code":code,@"client_id":self.clientId,@"client_secret":self.clientSecret};
	NSData * json = [NSJSONSerialization dataWithJSONObject:params options:0 error:nil];
	[request setValue:@"application/json; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
	request.HTTPMethod = @"POST";
	request.HTTPBody = json;
	
	__weak Dribbble * weakSelf = self;
	
	NSURLSessionDataTask * task = [self.defaultSession dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
		__strong Dribbble * strongSelf = weakSelf;
		NSDictionary * jsonData = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
		DribbbleResponse * dresponse = [[DribbbleResponse alloc] init];
		if([jsonData objectForKey:@"error"]) {
			NSError * error = [NSError errorWithDomain:DribbbleErrorDomain code:0 userInfo:jsonData];
			dresponse.error = error;
		}
		if([jsonData objectForKey:@"access_token"]) {
			strongSelf.accessToken = [[jsonData objectForKey:@"access_token"] copy];
		}
		strongSelf.authorizeCompletion(dresponse);
	}];
	
	[task resume];
}

#pragma mark shots

- (void) listShotsWithParameters:(NSDictionary *) params completion:(DribbbleCompletionBlock) completion; {
	NSMutableString * u = [NSMutableString stringWithFormat:@"https://api.dribbble.com/v1/shots"];
	NSMutableURLRequest * request = [self __requestWithAPIEndpoint:u method:nil params:params];
	__weak Dribbble * weakSelf = self;
	NSURLSessionDataTask * task = [self.defaultSession dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
		[weakSelf __handleExpectingJSONResponse:response data:data error:error completion:completion];
	}];
	[task resume];
}

- (void) likeShot:(NSString *) shotId withCompletion:(DribbbleCompletionBlock) completion; {
	NSMutableString * u = [NSMutableString stringWithFormat:@"https://api.dribbble.com/v1/shots/%@/like",shotId];
	NSMutableURLRequest * request = [self __requestWithAPIEndpoint:u method:@"POST" params:nil];
	__weak Dribbble * weakSelf = self;
	NSURLSessionTask * task = [self.defaultSession dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
		[weakSelf __handleExpectingJSONResponse:response data:data error:error completion:completion];
	}];
	[task resume];
}

- (void) unlikeShot:(NSString *) shotId withCompletion:(DribbbleCompletionBlock) completion; {
	NSMutableString * u = [NSMutableString stringWithFormat:@"https://api.dribbble.com/v1/shots/%@/like",shotId];
	NSMutableURLRequest * request = [self __requestWithAPIEndpoint:u method:@"DELETE" params:nil];
	__weak Dribbble * weakSelf = self;
	NSURLSessionTask * task = [self.defaultSession dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
		[weakSelf __handleExpectingEmptyResponse:response data:data error:error completion:completion];
	}];
	[task resume];
}

#pragma mark users

- (void) getUser:(NSString *) user completion:(DribbbleCompletionBlock) completion; {
	NSMutableString * u = [NSMutableString stringWithFormat:@"https://api.dribbble.com/v1/users/%@",user];
	NSMutableURLRequest * request = [self __requestWithAPIEndpoint:u method:nil params:nil];
	__weak Dribbble * weakSelf = self;
	NSURLSessionDataTask * task = [self.defaultSession dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
		[weakSelf __handleExpectingJSONResponse:response data:data error:error completion:completion];
	}];
	[task resume];
}

- (void) getAuthedUser:(DribbbleCompletionBlock) completion; {
	NSMutableString * u = [NSMutableString stringWithFormat:@"https://api.dribbble.com/v1/user"];
	NSMutableURLRequest * request = [self __requestWithAPIEndpoint:u method:nil params:nil];
	__weak Dribbble * weakSelf = self;
	NSURLSessionDataTask * task = [self.defaultSession dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
		[weakSelf __handleExpectingJSONResponse:response data:data error:error completion:completion];
	}];
	[task resume];
}

- (void) listShotsLikedParameters:(NSDictionary *) params withCompletion:(DribbbleCompletionBlock) completion; {
	NSMutableString * u = [NSMutableString stringWithFormat:@"https://api.dribbble.com/v1/user/likes"];
	NSMutableURLRequest * request = [self __requestWithAPIEndpoint:u method:nil params:params];
	__weak Dribbble * weakSelf = self;
	NSURLSessionDataTask * task = [self.defaultSession dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
		[weakSelf __handleExpectingJSONResponse:response data:data error:error completion:completion];
	}];
	[task resume];
}

- (void) listShotsOfPlayersFollowedParameters:(NSDictionary *) params withCompletion:(DribbbleCompletionBlock) completion; {
	NSMutableString * u = [NSMutableString stringWithFormat:@"https://api.dribbble.com/v1/user/following/shots"];
	NSMutableURLRequest * request = [self __requestWithAPIEndpoint:u method:nil params:params];
	__weak Dribbble * weakSelf = self;
	NSURLSessionDataTask * task = [self.defaultSession dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
		[weakSelf __handleExpectingJSONResponse:response data:data error:error completion:completion];
	}];
	[task resume];
}

- (void) listShotsOfUser:(NSString *) user parameters:(NSDictionary *) params withCompletion:(DribbbleCompletionBlock) completion; {
	NSMutableString * u = [NSMutableString stringWithFormat:@"https://api.dribbble.com/v1/users/%@/shots",user];
	NSMutableURLRequest * request = [self __requestWithAPIEndpoint:u method:nil params:params];
	__weak Dribbble * weakSelf = self;
	NSURLSessionDataTask * task = [self.defaultSession dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
		[weakSelf __handleExpectingJSONResponse:response data:data error:error completion:completion];
	}];
	[task resume];
}

- (void) followUser:(NSString *) user withCompletion:(DribbbleCompletionBlock) completion; {
	NSMutableString * u = [NSMutableString stringWithFormat:@"https://api.dribbble.com/v1/users/%@/follow",user];
	NSMutableURLRequest * request = [self __requestWithAPIEndpoint:u method:@"PUT" params:nil];
	__weak Dribbble * weakSelf = self;
	NSURLSessionDataTask * task = [self.defaultSession dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
		[weakSelf __handleExpectingEmptyResponse:response data:data error:error completion:completion];
	}];
	[task resume];
}

- (void) unfollowUser:(NSString *) user withCompletion:(DribbbleCompletionBlock) completion; {
	NSMutableString * u = [NSMutableString stringWithFormat:@"https://api.dribbble.com/v1/users/%@/follow",user];
	NSMutableURLRequest * request = [self __requestWithAPIEndpoint:u method:@"DELETE" params:nil];
	__weak Dribbble * weakSelf = self;
	NSURLSessionDataTask * task = [self.defaultSession dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
		[weakSelf __handleExpectingEmptyResponse:response data:data error:error completion:completion];
	}];
	[task resume];
}

- (void) getFollowedUsersWithParameters:(NSDictionary *) params withCompletion:(DribbbleCompletionBlock) completion; {
	NSMutableString * u = [NSMutableString stringWithFormat:@"https://api.dribbble.com/v1/user/following"];
	NSMutableURLRequest * request = [self __requestWithAPIEndpoint:u method:@"GET" params:params];
	__weak Dribbble * weakSelf = self;
	NSURLSessionDataTask * task = [self.defaultSession dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
		[weakSelf __handleExpectingJSONResponse:response data:data error:error completion:completion];
	}];
	[task resume];
}

- (void) getFollowersForAuthedUserWithParameters:(NSDictionary *) params withCompletion:(DribbbleCompletionBlock) completion; {
	NSMutableString * u = [NSMutableString stringWithFormat:@"https://api.dribbble.com/v1/user/followers"];
	NSMutableURLRequest * request = [self __requestWithAPIEndpoint:u method:@"GET" params:params];
	__weak Dribbble * weakSelf = self;
	NSURLSessionDataTask * task = [self.defaultSession dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
		[weakSelf __handleExpectingJSONResponse:response data:data error:error completion:completion];
	}];
	[task resume];
}

- (void) dealloc {
	NSLog(@"DEALLOC: Dribbble");
	[self.defaultSession finishTasksAndInvalidate];
}

#if DEBUG

- (void) URLSession:(NSURLSession *) session task:(NSURLSessionTask *) task didReceiveChallenge:(NSURLAuthenticationChallenge *) challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *credential))completionHandler {
	completionHandler(NSURLSessionAuthChallengeUseCredential,[NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust]);
}

#endif

@end

#pragma mark DribbbleResponse

@implementation DribbbleResponse

- (NSString *) description {
	if(self.data) {
		return [self.data description];
	}
	if(self.error) {
		return [self.error description];
	}
	return [super description];
}

- (void) dealloc {
	//NSLog(@"DEALLOC: DribbbleResponse");
}

@end

#pragma mark DribbbleShotsCollection

@implementation DribbbleShotsCollection

- (id) init {
	self = [super init];
	self.page = 1;
	self.content = [NSMutableArray array];
	self.parameters = [NSDictionary dictionary];
	return self;
}

- (id) initWithDribbble:(Dribbble *) dribbble parameters:(NSDictionary *) parameters; {
	self = [self init];
	if(parameters) {
		self.parameters = parameters;
	}
	self.dribbble = dribbble;
	return self;
}

- (void) loadContentWithCompletion:(DribbbleCollectionCompletionBlock) completion; {
	NSLog(@"DribbbleShotsCollection: Implement loadContentWithCompletion in a custom subclass.");
}

- (NSDictionary *) APICallParameters; {
	NSMutableDictionary * pams = [NSMutableDictionary dictionary];
	pams[@"page"] = [NSString stringWithFormat:@"%lu",self.page];
	for (NSString * key in self.parameters) {
		pams[key] = [self.parameters objectForKey:key];
	}
	return pams;
}

- (void) addContent:(NSArray *) content {
	[self.content addObjectsFromArray:content];
}

- (void) incrementPage; {
	self.page += 1;
}

- (void) reset; {
	self.page = 1;
	self.content = [NSMutableArray array];
}

- (void) dealloc {
	//NSLog(@"DEALLOC: DribbbleShotsCollection");
	if(self.dribbble) {
		[self.dribbble.defaultSession finishTasksAndInvalidate];
	}
}

@end
