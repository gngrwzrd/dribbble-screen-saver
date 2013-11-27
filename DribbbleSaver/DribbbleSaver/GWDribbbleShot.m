
#import "GWDribbbleShot.h"
#import "GWDribbbleSaver.h"

@interface GWDribbbleShot ()
@end

@implementation GWDribbbleShot

- (void) awakeFromNib {
	self.imageView.imageScaling = NSScaleToFit;
	self.spinner.displayedWhenStopped = FALSE;
	self.spinner.usesThreadedAnimation = FALSE;
	self.spinner.color = [NSColor whiteColor];
	
	ScreenSaverDefaults * defaults = [ScreenSaverDefaults defaultsForModuleWithName:@"com.gngrwzrd.HotShotsScreenSaver"];
	BOOL animateGifs = [[defaults objectForKey:@"animateGifs"] boolValue];
	if(animateGifs) {
		self.imageView.animates = TRUE;
	}
}

- (void) setIsLoading:(BOOL)isLoading {
	_isLoading = isLoading;
	if(isLoading) {
		if(self.imageView.image) {
			spinnerTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(startSpinner:) userInfo:nil repeats:FALSE];
		} else {
			spinnerTimer = [NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(startSpinner:) userInfo:nil repeats:FALSE];
		}
	} else {
		if(spinnerTimer) {
			[spinnerTimer invalidate];
			spinnerTimer = nil;
		}
		[self stopSpinner:nil];
	}
}

- (void) startSpinner:(id) sender {
	[self.spinner startAnimation:nil];
}

- (void) stopSpinner:(id) sender {
	[self.spinner stopAnimation:nil];
}

- (void) setRepresentedObject:(id) representedObject {
	NSURL * imgURL = [NSURL URLWithString:[[representedObject objectForKey:@"image_url"] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
	NSURLRequest * request = [NSURLRequest requestWithURL:imgURL cachePolicy:NSURLRequestReturnCacheDataElseLoad timeoutInterval:3000];
	
	GWDribbbleSaver * saver = [GWDribbbleSaver instance];
	
	/*
	if([saver.cache hasDataForRequest:request]) {
		NSData * data = [saver.cache dataForRequest:request];
		NSImage * image = [[NSImage alloc] initWithData:data];
		[self displayImage:image];
		return;
	}
	*/
	 
	self.isLoading = TRUE;
	[NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
		
		if(connectionError) {
			[saver loadFailedWithError:connectionError];
		}
		
		if(data) {
			[saver shotLoadCompleted];
			NSImage * image = [[NSImage alloc] initWithData:data];
			self.isLoading = FALSE;
			//if(![saver.cache hasDataForRequest:request]) {
			//	[saver.cache writeData:data forRequest:request];
			//}
			[self displayImage:image];
		}
	}];
}

- (void) displayImage:(NSImage *) image {
	//NSLog(@"%s",__FUNCTION__);
	//NSLog(@"%@",image);
	
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
	[NSAnimationContext endGrouping];
}

- (void) _displayImageFadeIn:(NSImage *) image {
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
