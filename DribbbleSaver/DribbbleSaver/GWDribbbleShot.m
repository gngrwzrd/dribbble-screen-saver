
#import "GWDribbbleShot.h"
#import "GWDribbbleSaver.h"
#import "NSURLRequest+Additions.h"

@interface GWDribbbleShot ()
@end

@implementation GWDribbbleShot

- (void) awakeFromNib {
	self.imageView.imageScaling = NSScaleToFit;
	ScreenSaverDefaults * defaults = [ScreenSaverDefaults defaultsForModuleWithName:@"com.gngrwzrd.HotShotsScreenSaver"];
	BOOL animateGifs = [[defaults objectForKey:@"animateGifs"] boolValue];
	if(animateGifs) {
		self.imageView.animates = TRUE;
	}
}

- (void) setRepresentedObject:(id) representedObject {
	GWDribbbleSaver * saver = [GWDribbbleSaver instance];
	NSDictionary * shot = representedObject;
	NSDictionary * images = shot[@"images"];
	NSString * _cachedImageFile = [[representedObject objectForKey:@"cache_shot_filename"] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
	NSString * _imgurl = [[images objectForKey:@"normal"] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
	
	if(![images[@"hidpi"] isEqualTo:[NSNull null]]) {
		_imgurl  = [[images objectForKey:@"hidpi"] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
	}
	
	NSString * _img400url = [[representedObject objectForKey:@"image_400_url"] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
	
	NSURL * imgURL = NULL;
	NSURL * fullCachedURL = NULL;
	
	if(_cachedImageFile) {
		fullCachedURL = [saver.cache.diskCacheURL URLByAppendingPathComponent:_cachedImageFile];
	}
	
	if(_cachedImageFile && [[NSFileManager defaultManager] fileExistsAtPath:fullCachedURL.path]) {
		
		imgURL = [saver.cache.diskCacheURL URLByAppendingPathComponent:_cachedImageFile];
		NSData * data = [NSData dataWithContentsOfFile:imgURL.path];
		NSImage * image = [[NSImage alloc] initWithData:data];
		[self displayImage:image];
		
		return;
		
	} else if(_img400url) {
		
		imgURL = [NSURL URLWithString:_img400url];
		
	} else {
		
		imgURL = [NSURL URLWithString:_imgurl];
		
	}
	
	NSURLRequest * request = [NSURLRequest requestWithURL:imgURL cachePolicy:NSURLRequestReturnCacheDataElseLoad timeoutInterval:3000];
	
#if GWDribbbleSaverUseCache

	if([saver.cache hasDataForRequest:request]) {
		NSData * data = [saver.cache dataForRequest:request];
		NSImage * image = [[NSImage alloc] initWithData:data];
		[self displayImage:image];
		return;
	}

#endif
	
	[NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
		
		if(connectionError) {
			NSLog(@"%@",connectionError);
			//[saver loadFailedWithError:connectionError];
		}
		
		if(data) {
			//[saver shotLoadCompleted];
			NSImage * image = [[NSImage alloc] initWithData:data];
			
#if GWDribbbleSaverUseCache
			if(![saver.cache hasDataForRequest:request]) {
				[saver.cache writeData:data forRequest:request];
			}
#endif
			
			[self displayImage:image];
		}
	}];
}

- (void) displayImage:(NSImage *) image {
	if(!self.imageView.image) {
		self.imageView.alphaValue = .6;
		self.imageView.image = image;
	} else {
		[self _displayImageOutFirst:image];
	}
}

- (void) _displayImageOutFirst:(NSImage *) image {
	[NSAnimationContext beginGrouping];
	[[NSAnimationContext currentContext] setDuration:1];
	[[NSAnimationContext currentContext] setCompletionHandler:^{
		[self _displayImageFadeIn:image];
	}];
	self.imageView.animator.alphaValue = 0;
	
	CGRect frame = self.imageView.frame;
	self.imageView.animator.frame = NSInsetRect(frame,10,10);
	[NSAnimationContext endGrouping];
}

- (void) _displayImageFadeIn:(NSImage *) image {
	CGRect frame = self.imageView.frame;
	self.imageView.frame = NSInsetRect(frame,-10,-10);
	self.imageView.image = image;
	
	[NSAnimationContext beginGrouping];
	[[NSAnimationContext currentContext] setDuration:1];
	self.imageView.animator.alphaValue = 1;
	[[NSAnimationContext currentContext] setCompletionHandler:^{
		[NSTimer scheduledTimerWithTimeInterval:4.25 target:self selector:@selector(_fadeOutSlightly:) userInfo:nil repeats:false];
	}];
	[NSAnimationContext endGrouping];
}

- (void) _fadeOutSlightly:(id) sender {
	[NSAnimationContext beginGrouping];
	[[NSAnimationContext currentContext] setDuration:1];
	self.imageView.animator.alphaValue = .6;
	[NSAnimationContext endGrouping];
}

@end
