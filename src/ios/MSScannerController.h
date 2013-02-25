/**
 * Copyright (c) 2013 Moodstocks SAS
 *
 * Permission is hereby granted, free of charge, to any person obtaining
 * a copy of this software and associated documentation files (the
 * "Software"), to deal in the Software without restriction, including
 * without limitation the rights to use, copy, modify, merge, publish,
 * distribute, sublicense, and/or sell copies of the Software, and to
 * permit persons to whom the Software is furnished to do so, subject to
 * the following conditions:
 *
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
 * LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
 * OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
 * WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

#import <UIKit/UIKit.h>

#import "MSScannerSession.h"
#import "MSActivityView.h"

@protocol MSScannerOverlayDelegate;
@class MSOverlayController;

@interface MSScannerController : UIViewController
<
MSActivityViewDelegate
#if MS_SDK_REQUIREMENTS
, MSScannerSessionDelegate
#endif
>
{
    MSOverlayController *_overlayController;
    MSScannerSession *_scannerSession;
    MSResult *_result; // previous result
    UIView *_videoPreview;
}

/**
 * Flush the last recognized result (if any) and start scanning again
 */
- (void)resume;

@end

@protocol MSScannerOverlayDelegate <NSObject>
/**
 * Used to communicate a scanning result to the overlay
 */
- (void)scanner:(MSScannerController *)scanner resultFound:(MSResult *)result;

@optional

/**
 * Used to communicate any information (e.g. options, etc) that may be shown on the overlay side
 */
- (void)scanner:(MSScannerController *)scanner stateUpdated:(NSDictionary *)state;
@end
