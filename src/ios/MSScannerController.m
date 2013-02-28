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

#import "MSOverlayController.h"
#import "MSDebug.h"
#import "MSImage.h"

#include "moodstocks_sdk.h"

/**
 * Enabled scanning formats
 * Here we only allow offline image recognition.
 * Feel free to add barcodes decoding flags according to your needs
 * e.g. to enable EAN-13 decoding in addition use:
 *   MS_RESULT_TYPE_IMAGE | MS_RESULT_TYPE_EAN13
 *
 * See moodstocks_sdk.h for the list of available flags
 */
static NSInteger kMSScanOptions = MS_RESULT_TYPE_IMAGE;

/* Private stuff */
@interface MSScannerController ()

- (void)showFlash;
- (void)setActivityView:(BOOL)show;

- (void)snapAction:(UIGestureRecognizer *)gestureRecognizer;
- (void)dismissAction;

- (void)deviceOrientationDidChange;

@end


@implementation MSScannerController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        UIBarButtonItem *barButton = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                    target:self
                                                                                    action:@selector(dismissAction)] autorelease];
        self.navigationItem.leftBarButtonItem = barButton;

        _scannerSession = [[MSScannerSession alloc] initWithScanner:[MSScanner sharedInstance]];
#if MS_SDK_REQUIREMENTS
        [_scannerSession setScanOptions:kMSScanOptions];
        [_scannerSession setDelegate:self];
#endif

        _overlayController = [[MSOverlayController alloc] init];
        
        [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(deviceOrientationDidChange)
                                                     name:UIDeviceOrientationDidChangeNotification
                                                   object:nil];
    }
    return self;
}

- (void)dealloc {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIDeviceOrientationDidChangeNotification
                                                  object:nil];
    [[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
    
    [_overlayController release];
    _overlayController = nil;

    [_scannerSession release];

    [_result release];
    _result = nil;
        
    [super dealloc];
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

- (void)setActivityView:(BOOL)show {
    MSActivityView *activityIndicator = nil;
    if (show) {
        CGRect statusFrame = [UIApplication sharedApplication].statusBarFrame;
        CGFloat offsetY = statusFrame.size.height + 44 /* toolbar height in portrait */;
        CGRect frame = CGRectMake(0, offsetY, self.view.frame.size.width, self.view.frame.size.height);
        activityIndicator = [[MSActivityView alloc] initWithFrame:frame];
        activityIndicator.text = @"Searching...";
        activityIndicator.isAnimating = YES;
        activityIndicator.delegate = self;
        // Place this view at the navigation controller level to make sure it ignores tap gestures
        [self.navigationController.view addSubview:activityIndicator];
        [activityIndicator release];
    }
    else {
        for (UIView *v in [self.navigationController.view subviews]) {
            if ([v isKindOfClass:[MSActivityView class]]) {
                activityIndicator = (MSActivityView *) v;
                break;
            }
        }
        [activityIndicator removeFromSuperview];
    }
}

- (void)deviceOrientationDidChange
{
    captureVideoPreviewLayer = (AVCaptureVideoPreviewLayer *)[_scannerSession previewLayer];
    [[captureVideoPreviewLayer connection] setVideoOrientation:[[UIDevice currentDevice] orientation]];
    
    // update capture layer frame - must be a better way!!!
    CGFloat w = self.view.frame.size.width;
    CGFloat h = self.view.frame.size.height;
    
    CGRect frame;
    
    switch (orientation)
    {
        case UIDeviceOrientationLandscapeLeft:
        case UIDeviceOrientationLandscapeRight:
            frame = CGRectMake(0, 0, h, w);
            break;
            
        case UIDeviceOrientationPortrait:
        case UIDeviceOrientationPortraitUpsideDown:
        case UIDeviceOrientationFaceDown:
        case UIDeviceOrientationFaceUp:
        case UIDeviceOrientationUnknown:
            frame = CGRectMake(0, 0, w, h);
            break;
    }

    [captureVideoPreviewLayer setFrame:frame];

}

#pragma mark - View lifecycle

- (void)loadView {
    [super loadView];

    CGFloat w = self.view.frame.size.width;
    CGFloat h = self.view.frame.size.height;

    CGRect videoFrame = CGRectMake(0, 0, w, h);
    _videoPreview = [[UIView alloc] initWithFrame:videoFrame];
    _videoPreview.backgroundColor = [UIColor blackColor];
    _videoPreview.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _videoPreview.autoresizesSubviews = YES;
    [self.view addSubview:_videoPreview];

    [_overlayController.view setFrame:CGRectMake(0, 0, w, h)];
    [self.view addSubview:_overlayController.view];

    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                    action:@selector(snapAction:)];
    tapRecognizer.numberOfTapsRequired = 1;
    [self.view addGestureRecognizer:tapRecognizer];
    [tapRecognizer release];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    self.navigationController.navigationBar.tintColor = nil;

    CALayer *videoPreviewLayer = [_videoPreview layer];
    [videoPreviewLayer setMasksToBounds:YES];

    // force preview layer orientation to device orientation
    captureVideoPreviewLayer = (AVCaptureVideoPreviewLayer *)[_scannerSession previewLayer];
    [captureVideoPreviewLayer setFrame:[_videoPreview bounds]];
    [[captureVideoPreviewLayer connection] setVideoOrientation:[[UIDevice currentDevice] orientation]];

    [videoPreviewLayer insertSublayer:captureVideoPreviewLayer below:[[videoPreviewLayer sublayers] objectAtIndex:0]];

    // Try again to synchronize if the last sync failed
    id<UIApplicationDelegate> appDelegate = [[UIApplication sharedApplication] delegate];
    if ([appDelegate respondsToSelector:@selector(scannerSyncError)] &&
        [appDelegate respondsToSelector:@selector(scannerSync)]) {
        if ([appDelegate performSelector:@selector(scannerSyncError)] != MS_SUCCESS)
            [appDelegate performSelector:@selector(scannerSync)];
    }

    [_scannerSession startCapture];

    NSDictionary *state = [NSDictionary dictionaryWithObjectsAndKeys:
                           [NSNumber numberWithBool:!!(kMSScanOptions & MS_RESULT_TYPE_EAN8)],   @"decode_ean_8",
                           [NSNumber numberWithBool:!!(kMSScanOptions & MS_RESULT_TYPE_EAN13)],  @"decode_ean_13",
                           [NSNumber numberWithBool:!!(kMSScanOptions & MS_RESULT_TYPE_QRCODE)], @"decode_qrcode",
                           [NSNumber numberWithBool:!!(kMSScanOptions & MS_RESULT_TYPE_DMTX)],   @"decode_datamatrix", nil];
    [_overlayController scanner:self stateUpdated:state];
}

- (void)viewDidUnload {
    [super viewDidUnload];

    [_videoPreview release];
    _videoPreview = nil;
}

// IOS 6
- (BOOL)shouldAutorotate {
    return self.presentingViewController.shouldAutorotate;
}

- (NSUInteger)supportedInterfaceOrientations {
    return self.presentingViewController.supportedInterfaceOrientations;
}

// IOS < 6 - FIXME : need to use defined orientation
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
	return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Actions

- (void)snapAction:(UIGestureRecognizer *)gestureRecognizer {
    [self showFlash];
    [_scannerSession snap];
}

- (void)dismissAction {
    [_scannerSession stopCapture];

    // This is to make sure any pending API search is cancelled
    [_scannerSession cancel];
    [self dismissModalViewControllerAnimated:YES];
}

#pragma mark - MSScannerSessionDelegate

#if MS_SDK_REQUIREMENTS

- (void)session:(MSScannerSession *)session didScan:(MSResult *)result {
    // Notify the overlay
    // --
    if (result != nil) {
        // We choose to notify only if a *new* result has been found
        if (![_result isEqualToResult:result]) {
            [_result release];
            _result = [result copy];

            // This is to prevent the scanner to keep scanning while a result
            // is shown on the overlay side (see `resume` method below)
            [_scannerSession pause];

            dispatch_async(dispatch_get_main_queue(), ^{
                [_overlayController scanner:self resultFound:result];
            });
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.scannerDelegate scanner:self didScan:[result getValue]];
            });
        }
    }
}

- (void)session:(MSScannerSession *)scanner failedToScan:(NSError *)error {
    MSDLog(@" [MOODSTOCKS SDK] SCAN ERROR: %@", MSErrMsg([error code]));
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.scannerDelegate scanner:self failedToScan:MSErrMsg([error code])];
    });
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
        [_overlayController scanner:self resultFound:result];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.scannerDelegate scanner:self didScan:[result getValue]];
        });
    }
    else {
        // Feel free to choose the proper UI component used to warn the user
        // that the API search could not found a match
        [[[[UIAlertView alloc] initWithTitle:@"No match found"
                                     message:nil
                                    delegate:nil
                           cancelButtonTitle:@"OK"
                           otherButtonTitles:nil] autorelease] show];

        dispatch_async(dispatch_get_main_queue(), ^{
            [self.scannerDelegate scanner:self didScan:@"No match found"];
        });
        
    }
}

- (void)scanner:(MSScanner *)scanner failedToSearchWithError:(NSError *)error {
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    [self setActivityView:NO];

    ms_errcode ecode = [error code];
    // NOTE: ignore negative error codes (e.g. -1 when the request has been cancelled)
    if (ecode >= 0) {
        NSString *errStr = MSErrMsg(ecode);

        MSDLog(@" [MOODSTOCKS SDK] FAILED TO SEARCH WITH ERROR: %@", errStr);

        // Here you may want to inform the user that an error occurred
        // Fee free to adapt to your needs (wording, display policy, etc)
        switch (ecode) {
            case MS_NOCONN:
                errStr = @"No Internet connection.";
                break;

            case MS_TIMEOUT:
                errStr = @"The request timed out.";
                break;

            default:
                errStr = [NSString stringWithFormat:@"An error occurred (code = %d).", ecode];
                break;
        }

        // Feel free to choose the proper UI component to warn the user that an error occurred
        [[[[UIAlertView alloc] initWithTitle:@"Search error"
                                     message:errStr
                                    delegate:nil
                           cancelButtonTitle:@"OK"
                           otherButtonTitles:nil] autorelease] show];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.scannerDelegate scanner:self failedToScan:errStr];
        });
    }
}
#endif

#pragma mark - MSActivityViewDelegate

- (void)activityViewDidCancel:(MSActivityView *)view {
    [_scannerSession cancel];
}

#pragma mark - Public

- (void)resume {
    [_result release];
    _result = nil;
    [_scannerSession resume];
}

- (void)pause {
    [self dismissAction];
}

@end
