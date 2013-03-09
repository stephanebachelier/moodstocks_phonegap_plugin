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

#import "MSScannerController.h"
#import "MoodstocksPlugin.h"
#import "MSOverlayView.h"

#import "MSDebug.h"
#import "MSImage.h"

#include "moodstocks_sdk.h"

@interface MSScannerController ()
- (void)showFlash;
- (void)setActivityView:(BOOL)show;
- (void)snapAction:(UIGestureRecognizer *)gestureRecognizer;
- (void)dismissAction;
@end

@implementation MSScannerController

@synthesize handler = _handler;

- (id)initWithHandler:(MSHandler *)handler scanOptions:(NSInteger)scanOptions {
    self = [super init];
    if (self) {

        self.handler = handler;
        _scanOptions = scanOptions;
        
        _scannerSession = [[MSScannerSession alloc] initWithScanner:[MSScanner sharedInstance]];
#if MS_SDK_REQUIREMENTS
        [_scannerSession setScanOptions:_scanOptions];
        [_scannerSession setDelegate:self];
#endif
    }
    
    return self;
}

- (void)dealloc {
    [super dealloc];
    
    self.handler = nil;
    [_scannerSession release];
}

- (void)loadView {
    [super loadView];
    
    CGFloat w = self.view.frame.size.width;
    CGFloat h = self.view.frame.size.height;
    
    CGRect videoFrame = CGRectMake(0, 0, w, h);
    _videoPreview = [[[UIView alloc] initWithFrame:videoFrame] autorelease];
    _videoPreview.backgroundColor = [UIColor blackColor];
    _videoPreview.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _videoPreview.autoresizesSubviews = YES;
    [self.view addSubview:_videoPreview];
    
    _tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                             action:@selector(snapAction:)];
    _tapRecognizer.numberOfTapsRequired = 1;
    [self.view addGestureRecognizer:_tapRecognizer];
    [_tapRecognizer release];
    
    // Set the tapGesture's delegate to scanner controller
    _tapRecognizer.delegate = self;
    
    CGRect overlayFrame = CGRectMake(0, 44, w, h);
    _overlayView = [[[MSOverlayView alloc] initWithFrame:overlayFrame] autorelease];
    [self.view addSubview:_overlayView];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    self.navigationController.navigationBar.tintColor = nil;
    
    CALayer *videoPreviewLayer = [_videoPreview layer];
    [videoPreviewLayer setMasksToBounds:YES];
    
    CALayer *captureLayer = [_scannerSession previewLayer];
    [captureLayer setFrame:[_videoPreview bounds]];
    
    [videoPreviewLayer insertSublayer:captureLayer below:[[videoPreviewLayer sublayers] objectAtIndex:0]];
    
    [_scannerSession startCapture];
    
    NSDictionary *state = [NSDictionary dictionaryWithObjectsAndKeys:
                           [NSNumber numberWithBool:!!(_scanOptions & MS_RESULT_TYPE_EAN8)],   @"decode_ean_8",
                           [NSNumber numberWithBool:!!(_scanOptions & MS_RESULT_TYPE_EAN13)],  @"decode_ean_13",
                           [NSNumber numberWithBool:!!(_scanOptions & MS_RESULT_TYPE_QRCODE)], @"decode_qrcode",
                           [NSNumber numberWithBool:!!(_scanOptions & MS_RESULT_TYPE_DMTX)],   @"decode_datamatrix", nil];

    [_overlayView scanner:self stateUpdated:state];
    
    _toolbar = [[[UIToolbar alloc] init] autorelease];
    _toolbar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
    _toolbar.barStyle = UIBarStyleBlack;
    _toolbar.tintColor = nil;
    
    _barButton = [[[UIBarButtonItem alloc]
                   initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                   target:self
                   action:@selector(dismissAction)] autorelease];
    
    id flexSpace = [[[UIBarButtonItem alloc]
                    initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                    target:nil
                    action:nil] autorelease];
    
    _toolbar.items = [NSArray arrayWithObjects:_barButton,flexSpace,nil];
    [_toolbar sizeToFit];
    CGFloat toolbarHeight = _toolbar.frame.size.height;
    CGFloat rootViewWidth = CGRectGetWidth(self.view.bounds);
    CGRect rectArea = CGRectMake(0, 0, rootViewWidth, toolbarHeight);
    [_toolbar setFrame:rectArea];
    
    [self.view addSubview:_toolbar];
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    // Disallow recognition of tap gestures in the toolbar or on the activity indicator.
    if ((([touch.view.superview isKindOfClass:[UIToolbar class]]) ||
         ([touch.view isKindOfClass:[MSActivityView class]])) &&
         (gestureRecognizer == _tapRecognizer)) {
        return NO;
    }
    return YES;
}

#pragma mark -
#pragma mark Autorotation setting

// Here we block the scanner in portrait orientation
- (BOOL)shouldAutorotate {
    return NO;
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return NO;
}

#pragma mark - Private stuff

- (void)showFlash {
    CGRect frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
    UIView *flashView = [[UIView alloc] initWithFrame:frame];
    [flashView setBackgroundColor:[UIColor whiteColor]];
    [self.view addSubview:flashView];
    
    void (^animate)(void) = ^{
        [flashView setAlpha:0.f];
    };
    
    void (^finish)(BOOL finished) = ^(BOOL finished){
        [flashView removeFromSuperview];
        [flashView release];
    };
    
    [UIView animateWithDuration:.4f animations:animate completion:finish];
}

- (void)snapAction:(UIGestureRecognizer *)gestureRecognizer {
    [self showFlash];
    [_scannerSession snap];
}

- (void)setActivityView:(BOOL)show {
    MSActivityView *activityIndicator = nil;
    if (show) {
        CGRect frame = CGRectMake(0, _toolbar.frame.size.height, self.view.frame.size.width, self.view.frame.size.height);
        activityIndicator = [[MSActivityView alloc] initWithFrame:frame];
        activityIndicator.text = @"Searching...";
        activityIndicator.isAnimating = YES;
        activityIndicator.delegate = self;
        
        [self.view addSubview:activityIndicator];
        [activityIndicator release];
    }
    else {
        for (UIView *v in [self.view subviews]) {
            if ([v isKindOfClass:[MSActivityView class]]) {
                activityIndicator = (MSActivityView *) v;
                break;
            }
        }
        [activityIndicator removeFromSuperview];
    }
}

- (void)dismissAction {
    [_scannerSession stopCapture];
    [_scannerSession cancel];
    [self dismissModalViewControllerAnimated:YES];
}

#pragma mark - MSScannerSessionDelegate

#if MS_SDK_REQUIREMENTS
- (void)session:(MSScannerSession *)scanner didScan:(MSResult *)result {
    if (result != nil){
        [_scannerSession pause];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            NSString *value = [result getValue];
            int format = [result getType];
                    
            [self.handler scanResultFound:value format:format];
            [self dismissAction];
        });
    }
}

- (void)session:(MSScannerSession *)scanner failedToScan:(NSError *)error {
    MSDLog(@" [MOODSTOCKS SDK] SCAN ERROR: %@", MSErrMsg([error code]));
}

- (void)scannerWillSearch:(MSScanner *)scanner {
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    
    [self setActivityView:YES];
}

- (void)scanner:(MSScanner *)scanner didSearchWithResult:(MSResult *)result {
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    
    [self setActivityView:NO];
    
    if (result != nil) {
        [_scannerSession pause];
        
        NSString *value = [result getValue];
        int format = [result getType];
        
        [self.handler scanResultFound:value format:format];
        [self dismissAction];
    }
    else {
        [[[[UIAlertView alloc] initWithTitle:@"No match found"
                                     message:nil
                                    delegate:nil
                           cancelButtonTitle:@"OK"
                           otherButtonTitles:nil] autorelease] show];
    }
}

- (void)scanner:(MSScanner *)scanner failedToSearchWithError:(NSError *)error {
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    [self setActivityView:NO];
    
    ms_errcode ecode = [error code];
    // NOTE: ignore negative error codes (e.g. -1 when the request has been cancelled)
    if (ecode >= 0) {
        MSDLog(@" [MOODSTOCKS SDK] FAILED TO SEARCH WITH ERROR: %@", MSErrMsg(ecode));
        
        [[[[UIAlertView alloc] initWithTitle:@"Search error"
                                     message:MSErrMsg(ecode)
                                    delegate:nil
                           cancelButtonTitle:@"OK"
                           otherButtonTitles:nil] autorelease] show];
    }
}
#endif

#pragma mark - MSActivityViewDelegate

- (void)activityViewDidCancel:(MSActivityView *)view {
    [_scannerSession cancel];
}

@end
