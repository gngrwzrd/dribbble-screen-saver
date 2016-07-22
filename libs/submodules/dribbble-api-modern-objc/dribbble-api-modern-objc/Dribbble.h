
#import <Cocoa/Cocoa.h>

//forwards
@class Dribbble;
@class DribbbleResponse;
@class DribbbleShotsCollection;

//error domain
extern NSString * const DribbbleErrorDomain;

//error coes
extern NSInteger const DribbbleErrorCodeBadCredentials;

//scopes
extern NSString * const DribbbleScopePublic;
extern NSString * const DribbbleScopeWrite;
extern NSString * const DribbbleScopeComment;
extern NSString * const DribbbleScopeUpload;

//completions
typedef void (^DribbbleCompletionBlock)(DribbbleResponse * response);
typedef void (^DribbbleCollectionCompletionBlock)(Dribbble * dribbble, DribbbleResponse * response);

//main Dribbble class
@interface Dribbble : NSObject <NSURLSessionDelegate>

//default configured session.
@property NSURLSession * defaultSession;

//auth properties
@property NSString * clientId;
@property NSString * clientSecret;
@property NSString * accessToken;

//authorize
- (void) authorizeWithScopes:(NSArray *) scopes completion:(DribbbleCompletionBlock) completion;
- (void) handleCustomSchemeCallback:(NSString *) url;

//shots
- (void) listShotsWithParameters:(NSDictionary *) params completion:(DribbbleCompletionBlock) completion;
- (void) likeShot:(NSString *) shotId withCompletion:(DribbbleCompletionBlock) completion;
- (void) unlikeShot:(NSString *) shotId withCompletion:(DribbbleCompletionBlock) completion;

//user
- (void) getUser:(NSString *) user completion:(DribbbleCompletionBlock) completion;
- (void) getAuthedUser:(DribbbleCompletionBlock) completion;
- (void) listShotsLikedParameters:(NSDictionary *) params withCompletion:(DribbbleCompletionBlock) completion;
- (void) listShotsOfPlayersFollowedParameters:(NSDictionary *) params withCompletion:(DribbbleCompletionBlock) completion;
- (void) listShotsOfUser:(NSString *) user parameters:(NSDictionary *) params withCompletion:(DribbbleCompletionBlock) completion;
- (void) followUser:(NSString *) user withCompletion:(DribbbleCompletionBlock) completion;
- (void) unfollowUser:(NSString *) user withCompletion:(DribbbleCompletionBlock) completion;
- (void) getFollowedUsersWithParameters:(NSDictionary *) params withCompletion:(DribbbleCompletionBlock) completion;
- (void) getFollowersForAuthedUserWithParameters:(NSDictionary *) params withCompletion:(DribbbleCompletionBlock) completion;

@end

//response object for all asynchronous dribbble methods.
@interface DribbbleResponse : NSObject
@property id data;
@property NSError * error;
@end

//custom collection object to gather shots however needed.
//subclass this and use a Dribbble instance to do whatever is needed
//for the overall collection of shots.
@interface DribbbleShotsCollection : NSObject
@property Dribbble * dribbble;
@property NSMutableArray * content;
@property NSDictionary * parameters;
@property NSUInteger page;
- (id) initWithDribbble:(Dribbble *) dribbble parameters:(NSDictionary *) parameters;
- (void) loadContentWithCompletion:(DribbbleCollectionCompletionBlock) completion;
- (void) addContent:(NSArray *) content;
- (void) incrementPage;
- (void) reset;
- (NSDictionary *) APICallParameters;
@end
