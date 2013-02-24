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

#import <Foundation/Foundation.h>

#import "MSAvailability.h"

#if MS_IPHONE_OS_REQUIREMENTS
  #import <AVFoundation/AVFoundation.h>
#endif

@protocol MSCaptureSessionDelegate;

@interface MSCaptureSession : NSObject
#if MS_IPHONE_OS_REQUIREMENTS
<AVCaptureVideoDataOutputSampleBufferDelegate>
#endif
{
#if MS_IPHONE_OS_REQUIREMENTS
    AVCaptureSession *_captureSession;
    AVCaptureVideoPreviewLayer *_previewLayer;
    AVCaptureVideoOrientation _orientation;
    AVCaptureDeviceInput *_videoInput;
    AVCaptureVideoDataOutput *_videoOutput;
#endif
#if __has_feature(objc_arc_weak)
    id<MSCaptureSessionDelegate> __weak _delegate;
#elif __has_feature(objc_arc)
    id<MSCaptureSessionDelegate> __unsafe_unretained _delegate;
#else
    id<MSCaptureSessionDelegate> _delegate;
#endif
}

#if MS_IPHONE_OS_REQUIREMENTS
@property (nonatomic, readonly) AVCaptureVideoPreviewLayer *previewLayer;
@property (nonatomic, assign) AVCaptureVideoOrientation orientation;
#endif
#if __has_feature(objc_arc_weak)
@property (nonatomic, weak) id<MSCaptureSessionDelegate> delegate;
#elif __has_feature(objc_arc)
@property (nonatomic, unsafe_unretained) id<MSCaptureSessionDelegate> delegate;
#else
@property (nonatomic, assign) id<MSCaptureSessionDelegate> delegate;
#endif

/** Start the video capture */
- (void)start;
/** Stop the video capture and clean up */
- (void)stop;
/** Unfreeze the video capture */
- (void)play;
/** Freeze the video capture */
- (void)pause;

@end


@protocol MSCaptureSessionDelegate <NSObject>
#if MS_IPHONE_OS_REQUIREMENTS
- (void)session:(MSCaptureSession *)session didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer;
#endif
@end
