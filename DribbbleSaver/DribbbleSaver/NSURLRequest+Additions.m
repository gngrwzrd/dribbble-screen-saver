
#import "NSURLRequest+Additions.h"

@implementation NSURLRequest (GWAdditions)

+ (BOOL) allowsAnyHTTPSCertificateForHost:(NSString*) host; {
	return TRUE;
}

@end
