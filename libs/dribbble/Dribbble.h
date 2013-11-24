
#import <Foundation/Foundation.h>
#if TARGET_OS_MAC
	#import <AppKit/AppKit.h>
#endif

#if TARGET_OS_IPHONE
	#import <UIKit/UIKit.h>
#endif

#pragma mark Forwards

@class Dribbble;
@class DribbbleResponse;
@protocol DribbbleShotsMerger;

#pragma mark Typdefs

//block callback for asynch method calls
typedef void (^DribbbleCompletionBlock)(DribbbleResponse * response);

//possible values for dribbble.pagerType
typedef enum DribbblePagerType {
	DribbblePagerTypeEveryone             = 1,
	DribbblePagerTypePopular              = 2,
	DribbblePagerTypeDebut                = 3,
	DribbblePagerTypeFollowedPlayerShots  = 4,
} DribbblePagerType;

typedef enum DribbblePagerLoadOperation {
	DribbblePagerLoadOperationPreloading = 1,
	DribbblePagerLoadOperationLoadingNextPageOnly,
	DribbblePagerLoadOperationLoadingFirstPageOnly
} DribbblePagerLoadOperation;

//=== Dribbble
#pragma mark Dribbble

//Instances of Dribbble are used to load multiple pages of dribbble content.
//It's not a traditional pager though. The only functionality provided is to
//load enough pages of shots to fill the @minShotsCount. Anytime load is called
//the pager starts over at page=1, the new shots are inserted into the beginning
//of the @shots array, and N shots are removed from the end of @shots array.
@interface Dribbble : NSObject <NSCoding> {
	BOOL _loading;
	DribbblePagerType _pagerType;
	NSMutableArray * _mutableShots;
	NSMutableArray * _freshShots;
	NSInteger _currentPage;
	NSInteger _pagesToLoad;
}

//shots to load per page, default=50. max=50.
@property NSInteger perPage;

//default = 200, 4 pages of 50 are loaded. If this is changed then N pages of
//@perPage are loaded until @minShotsCount is filled. If there aren't enough shots
//in dribbble's feed then this may not always be met.
@property NSInteger minShotsCount;

//player name for initFollowingShotsPager.
@property (nonatomic,readonly) NSString * playerName;

//dribbble shots NSMutableArray<NSMutablueDictionary>.
@property (readonly) NSMutableArray * shots;

//the URL to serialize instance to when using "writeDataToSerializationURLAtomically:"
@property NSURL * serializationURL;

//@see DribbbleShotsMerger protocol definition.
@property NSObject <DribbbleShotsMerger> * shotsMerger;

//use methods below to create a pager instance for loading pages of dribbble shots.
+ (Dribbble *) deserializedPagerInstanceAtURL:(NSURL *) url;
- (Dribbble *) initEveryonePager;
- (Dribbble *) initPopularPager;
- (Dribbble *) initDebutPager;
- (Dribbble *) initFollowedPlayerShotsPager:(NSString *)playerName;

//Calling load always loads from pages 1-N until @minShotsCount is filled.
- (DribbbleResponse *) load:(DribbbleCompletionBlock)completion;

- (DribbbleResponse *) loadPage:(NSInteger) page completion:(DribbbleCompletionBlock) completion;
- (DribbbleResponse *) loadPages:(NSInteger) pageCount completion:(DribbbleCompletionBlock) completion;

//write a Dribbble pager instance to a URL.
- (BOOL) writeDataToURL:(NSURL *) url atomically:(BOOL)atomically;

//write a Dribbble pager instance to a URL - the url set in dribbble.serializationURL.
- (BOOL) writeDataToSerializationURLAtomically:(BOOL)atomically;

//loadPages:(NSInteger) pages;
//- (DribbbleResponse *) loadPage:(NSInteger) page completion:(DribbbleCompletionBlock) completion; //can use -1 for last page.

/**
 * FOR ALL STATIC METHODS BELOW
 * If you provide a completion block, requests are sent _Asynchronously_ and use your block for completion.
 * If you don't provide a completion, requests are sent _Synchronously_ and return DribbbbleCompletion object back to you.
 * POSSIBLE OPTIONS:
 * @{@"page":@"1", @"per_page":@"15"}
 */

//shots
+ (DribbbleResponse *) everyoneShotsWithOptions:(NSDictionary *)options completion:(DribbbleCompletionBlock)completion;
+ (DribbbleResponse *) popularShotsWithOptions:(NSDictionary *)options completion:(DribbbleCompletionBlock)completion;
+ (DribbbleResponse *) debutShotsWithOptions:(NSDictionary *)options completion:(DribbbleCompletionBlock)completion;
+ (DribbbleResponse *) shotWithId:(NSString *)sid options:(NSDictionary *)options completion:(DribbbleCompletionBlock)completion;
+ (DribbbleResponse *) playerShots:(NSString *)player option:(NSDictionary *)options completion:(DribbbleCompletionBlock)completion;
+ (DribbbleResponse *) followedPlayerShotsForPlayer:(NSString *) player option:(NSDictionary *)options completion:(DribbbleCompletionBlock)completion;
+ (DribbbleResponse *) likesForPlayer:(NSString *) player option:(NSDictionary *)options completion:(DribbbleCompletionBlock)completion;

//player
+ (DribbbleResponse *) player:(NSString *)player options:(NSDictionary *)options completion:(DribbbleCompletionBlock)completion;
+ (DribbbleResponse *) followers:(NSString *)player option:(NSDictionary *)options completion:(DribbbleCompletionBlock)completion;
+ (DribbbleResponse *) following:(NSString *)player option:(NSDictionary *)options completion:(DribbbleCompletionBlock)completion;
+ (DribbbleResponse *) playerDraftees:(NSString *)pid option:(NSDictionary *)options completion:(DribbbleCompletionBlock)completion;

//comments
+ (DribbbleResponse *) commentsForShotId:(NSString *)sid options:(NSDictionary *)options completion:(DribbbleCompletionBlock)completion;

@end

//===DribbbleShotsMerger
#pragma mark DribbbleShotsMerger

//When a Dribbble pager instance loads more shots, the shots loaded are given an
//opportunity to be merged into an array of existing shots from previous loads.
//You can set the dribbble.shotMerger to an instance NSObject<DribbbleSotsMerger>
//and sort/merge fresh shots into the existing pool of shots however you want.
//Return an array of shots that will be set for the property dribbble.mergedShots.
@protocol DribbbleShotsMerger <NSObject>

//perform the merge
- (void) mergeFreshShots:(NSMutableArray *) freshShots intoExistingShots:(NSMutableArray *) existingShots;

//get only the shots that were merged into existing shots.
- (NSArray *) mergedShots;

//a hook called when shots will load, when [dribbble load:] is called.
- (void) dribbbleShotsWillLoad:(Dribbble *) dribbble;

//another generic method you can user to reset anything.
- (void) reset;

@end

//The default shot merger used in Dribbble pager instances when shots are being
//merged into existing shots. @see @protocol(DribbbleShotsMerger).
@interface DribbbleShotsMergerDefault : NSObject <DribbbleShotsMerger> {
	NSArray * _mergedShots;
}
@end

//=== DribbbleResponse
#pragma mark DribbbleResponse

//DribbbleResponse objects are passed as parameters to completion blocks and
//returned to you when using synchronous method calls. Depending on how you use the
//API different properties are set (noted below).
@interface DribbbleResponse : NSObject

//set if an error occured
@property NSURLResponse * connectionResponse;

//set if an error occured
@property NSError * error;

//set when using a Dribbble instance as a pager. It's always set to the instance
//that initiated the page loading.
@property Dribbble * dribbble;

//only set when using the static [Dribbbble ...] utility methods
@property id jsonData;

@end
