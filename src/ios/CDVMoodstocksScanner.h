//
//  CDVMoodstocksScanner.h
//  Zelda
//
//  Created by Stéphane Bachelier on 2/15/13.
//
//

#import <Cordova/CDV.h>

#import "MSScanner.h"
#import "MSScannerController.h"

@interface CDVMoodstocksScanner: CDVPlugin <MSScannerDelegate, CDVScannerDelegate>

// YES if the device is compatible, NO otherwise
@property (assign, readonly) BOOL isScannerAvailable;

// Moodstocks SDK open error
@property (assign, readonly) ms_errcode scannerOpenError;

// Moodstocks SDK last sync error
@property (assign, readonly) ms_errcode scannerSyncError;

// save invoked command
@property (nonatomic, retain) CDVInvokedUrlCommand *command;

/**
 * _ API _
 */

// overwrite to setup moodstocks scanner
// NOTE: setup should be done at startup. 
//       New Cordova API will make this possible soon (see github repo)
- (CDVPlugin*)initWithWebView:(UIWebView*)theWebView;

- (void)scan:(CDVInvokedUrlCommand *)aCommand;

@end
