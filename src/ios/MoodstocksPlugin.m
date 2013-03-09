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
#import <Cordova/CDV.h>

#import "MoodstocksPlugin.h"
#import "MSScannerController.h"
#import "MSHandler.h"

#import "MSDebug.h"

#include "moodstocks_sdk.h"

// -------------------------------------------------
// Moodstocks API key/secret pair
// -------------------------------------------------
#define MS_API_KEY @"cfcidzpqnicio0b6oeya"
#define MS_API_SEC @"OxyJxsGlmyNgWS8G"

@class MSScannerController;

@implementation MoodstocksPlugin

// Plugin method - open: load the scanner with given api key & secret pair
- (void)open:(CDVInvokedUrlCommand *)command {
    CDVPluginResult *pluginResult = nil;
    
    if (!MSDeviceCompatibleWithSDK()) {
        MSDLog(@" [MOODSTOCKS SDK] DEVICE NOT COMPATIBLE");
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                         messageAsString:@"Your device is not compatible with the Moodstocks SDK."];
    }
    else {
#if MS_SDK_REQUIREMENTS
        NSError *err;
        MSScanner *scanner = [MSScanner sharedInstance];
        
        if(![scanner openWithKey:MS_API_KEY secret:MS_API_SEC error:&err]) {
            ms_errcode ecode = [err code];
            // == DO NOT USE IN PRODUCTION: THIS IS A HELP MESSAGE FOR DEVELOPERS
            if (ecode == MS_CREDMISMATCH) {
                NSString *errStr = @"there is a problem with your key/secret pair: "
                "the current pair does NOT match with the one recorded within the on-disk datastore.";
                MSDLog(@"\n\n [MOODSTOCKS SDK] SCANNER OPEN ERROR: %@", errStr);
                
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:errStr];

            }
            // == DO NOT USE IN PRODUCTION: THIS IS A HELP MESSAGE FOR DEVELOPERS
            else {
                NSString *errStr = MSErrMsg(ecode);
                MSDLog(@"[MOODSTOCKS SDK] SCANNER OPEN ERROR: %@", errStr);
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:errStr];
            }
        }
        else {
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK
                                             messageAsString:@"Scanner open succeeded."];
        }
#endif
    }
    
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

// Plugin method - sync: sync the cache
- (void)sync:(CDVInvokedUrlCommand *)command {
    // NOTE: will be released when sync is over (please refer to MSHandler.m)
    MSHandler *syncHandler = [[MSHandler alloc] initWithPlugin:self callback:command.callbackId];
    [syncHandler sync];
    
    [syncHandler release];
}

// Plugin method - scan: set scan options & launch the scanner
- (void)scan:(CDVInvokedUrlCommand *) command {
    // Get the scan options
    NSInteger scanOptions = [[command.arguments objectAtIndex:0] integerValue];
    
    MSHandler *scanHandler = [[MSHandler alloc] initWithPlugin:self callback:command.callbackId];
    
    // Initialize the scanner view controller
    MSScannerController *scannerController = [[MSScannerController alloc] initWithHandler:scanHandler
                                                                              scanOptions:scanOptions];

    [self.viewController presentModalViewController:scannerController animated:YES];
    
    [scannerController release];
    [scanHandler release];    
}

// Scan result callback
- (void)returnScanResult:(NSString *)value
                  format:(int)format
                callback:(NSString *)callback {
    NSMutableDictionary *resultDict = [[[NSMutableDictionary alloc] init] autorelease];
    
    // Scan result format
    [resultDict setObject:[NSNumber numberWithInteger:format] forKey:@"format"];
    // Scan result content
    [resultDict setObject:value forKey:@"value"];
    
    CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK
                                            messageAsDictionary:resultDict];
    
    NSString *js = [result toSuccessCallbackString:callback];
    [self writeJavascript:js];
}

// Sync status callback
- (void)returnSyncStatus:(NSString *)message
                  status:(int)status
                progress:(int)progress
                callback:(NSString *)callback
      shouldKeepCallback:(BOOL)shouldKeepCallback {
    NSDictionary *statusDict = [NSDictionary dictionaryWithObjectsAndKeys:message, @"message",
                                                                          [NSNumber numberWithInt:status], @"status",
                                                                          [NSNumber numberWithFloat:progress], @"progress",
                                                                          nil];
    
    CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK
                                                messageAsDictionary:statusDict];
    
    [result setKeepCallbackAsBool:shouldKeepCallback];
    
    NSString *js = [result toSuccessCallbackString:callback];
    [self writeJavascript:js];
}

@end
