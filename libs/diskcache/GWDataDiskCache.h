
#import <Foundation/Foundation.h>

@interface GWDataDiskCache : NSObject {
	
}

@property NSURL * diskCacheURL;
@property (nonatomic) NSTimeInterval oldestAllowableFileTimeDelta; //seconds
@property BOOL logFilesNotCached;
@property BOOL logFilesRemoved;

- (id) initWithDiskCacheURL:(NSURL *) url;
- (void) clearOldFiles;
- (void) empty;
- (void) setOldestAllowableFileTimeDeltaToDayCount:(NSInteger) dayCount;
- (BOOL) writeData:(NSData *)data forRequest:(NSURLRequest *)request;
- (BOOL) writeData:(NSData *) data forResponse:(NSURLResponse *) response;
- (BOOL) hasDataForURL:(NSURL *) url;
- (BOOL) hasDataForRequest:(NSURLRequest *) request;
- (NSURL *) localCachedURLForURL:(NSURL *) url;
- (NSURL *) localCachedURLForRequest:(NSURLRequest *) request;
- (NSURLRequest *) localRequestForRequest:(NSURLRequest *) request;
- (NSData *) dataForRequest:(NSURLRequest *) request;
- (NSData *) dataForURL:(NSURL *) url;
- (CGFloat) oldestAllowableFileTimeDeltaInDays;

@end
