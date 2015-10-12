
#import <Foundation/Foundation.h>

@interface NSURLRequest (GWAdditions)
+ (BOOL) allowsAnyHTTPSCertificateForHost:(NSString *) host;
@end
