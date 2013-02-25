
#import "CDVMoodstocksScanner.h"

#import "moodstocks_sdk.h"
#import "CDVMoodstocksScannerAPI.h"

#import "MSDebug.h"

/* Private stuff */
@interface CDVMoodstocksScanner ()

- (void)scannerInit;
- (void)scannerSync;
- (void)sendScanResult:(CDVPluginResult *)pluginResult;

@end

@implementation CDVMoodstocksScanner

@synthesize isScannerAvailable;
@synthesize scannerOpenError;
@synthesize scannerSyncError;
@synthesize command;

- (void)pluginInitialize
{
    // Moodstocks SDK setup
    [self scannerInit];
}

- (void)scan:(CDVInvokedUrlCommand *)aCommand
{
    NSLog(@"scan command called");
    // save command
    self.command = aCommand;
    
    if (!isScannerAvailable)
    {
        NSLog(@"scanner not available");
        [self sendScanResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_IO_EXCEPTION
                                                   messageAsString:@"scanner not available"]
             ];
        return;
    }
    
    MSScannerController *scannerController = [[MSScannerController alloc] init];
    [scannerController setScannerDelegate:self];

    [self.viewController presentModalViewController:scannerController animated:YES];
    [scannerController release];
}

- (void)sendScanResult:(CDVPluginResult *)pluginResult
{
    NSLog(@"send scan result %@", [pluginResult toJSONString]);
    
    [self.commandDelegate sendPluginResult:pluginResult
                                callbackId:command.callbackId];
}

#pragma mark - Moodstocks SDK

- (void)scannerInit {
    isScannerAvailable = NO;
    scannerOpenError = -1;
    scannerSyncError = -1; // no sync yet
    if (MSDeviceCompatibleWithSDK()) {
#if MS_SDK_REQUIREMENTS
        isScannerAvailable = YES;
        scannerOpenError = MS_SUCCESS;
        NSError *err;
        MSScanner *scanner = [MSScanner sharedInstance];
        
        if (![scanner openWithKey:MS_API_KEY secret:MS_API_SEC error:&err]) {
            scannerOpenError = [err code];
            MSDLog(@"scanner open error %@", [err code]);
        }
        else {
            [self scannerSync];
        }
#endif
    }
}

- (void)scannerSync {
#if MS_SDK_REQUIREMENTS
    MSScanner *scanner = [MSScanner sharedInstance];
    if ([scanner isSyncing]) return;
    [scanner syncWithDelegate:self];
#endif
}

#pragma mark - CDVScannerDelegate protocol

- (void)scanner:(MSScannerController *)scanner didScan:(NSString *)result
{
    NSLog(@"scanner result : %@", result);
    
    [self sendScanResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK
                                           messageAsString:result]];
}

- (void)scanner:(MSScannerController *)scanner failedToScan:(NSString *)error
{
    NSLog(@"scanner failure : %@", error);
    
    [self sendScanResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                           messageAsString:error]];
}

#pragma mark - MSScannerDelegate protocol

// Dispatched when a synchronization is completed
- (void)scannerDidSync:(MSScanner *)scanner {
    scannerSyncError = MS_SUCCESS;
    NSLog(@" [MOODSTOCKS SDK] SYNC SUCCEEDED (%d IMAGE(S))", [scanner count:nil]);
}

// Dispatched when a synchronization failed
- (void)scanner:(MSScanner *)scanner failedToSyncWithError:(NSError *)error {
    ms_errcode ecode = [error code];
    if (ecode == MS_BUSY) return;
    scannerSyncError = ecode;
    MSDLog(@" [MOODSTOCKS SDK] SYNC ERROR: %@", MSErrMsg(ecode));
}

// Dispatched when an online search (aka API search) is completed
- (void)scanner:(MSScanner *)scanner didSearchWithResult:(MSResult *)result {
    NSLog(@" [MOODSTOCKS SDK] SEARCH FOUND SUCCEEDED : %@", [result getValue]);
}

// Dispatched when an online search (aka API search) failed
- (void)scanner:(MSScanner *)scanner failedToSearchWithError:(NSError *)error {
    ms_errcode ecode = [error code];
    if (ecode == MS_BUSY) return;
    scannerSyncError = ecode;
    MSDLog(@" [MOODSTOCKS SDK] SEARCH ERROR: %@", MSErrMsg(ecode));
}

@end