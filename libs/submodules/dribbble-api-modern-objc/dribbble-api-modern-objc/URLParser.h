
#import <Foundation/Foundation.h>

@interface URLParser : NSObject {
	NSArray * variables;
}

@property NSArray * variables;
- (id) initWithURLString:(NSString *) url;
- (NSString *) valueForVariable:(NSString *) varName;
@end