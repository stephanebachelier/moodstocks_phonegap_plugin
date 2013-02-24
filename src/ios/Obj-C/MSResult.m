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

#import "MSResult.h"
#import "MSAvailability.h"
#import "MSObjC.h"

@implementation MSResult

@synthesize handle = _result;

- (id)init {
    self = [super init];
    if (self) {
        _result = NULL;
    }
    return self;
}

- (id)initWithBytes:(const void *)bytes length:(NSUInteger)length type:(MSResultType)type {
    self = [self init];
#if MS_SDK_REQUIREMENTS
    if (self) {
        ms_result_new(bytes, length, type, &_result);
    }
#endif
    return self;
}

- (id)initWithResult:(const ms_result_t *)result {
    self = [self init];
#if MS_SDK_REQUIREMENTS
    if (self) {
        ms_result_dup(result, &_result);
    }
#endif
    return self;
}

- (NSString *)getValue {
    NSString *str = nil;
#if MS_SDK_REQUIREMENTS
    if (_result) {
        const char *bytes = NULL;
        int length;
        ms_result_get_data(_result, &bytes, &length);
        str = [[[NSString alloc] initWithBytes:bytes
                                        length:length
                                      encoding:NSUTF8StringEncoding] autorelease_stub];
    }
#endif
    return str;
}

- (NSData *)getData {
    NSData *data = nil;
#if MS_SDK_REQUIREMENTS
    if (_result) {
        const char *bytes = NULL;
        int length;
        ms_result_get_data(_result, &bytes, &length);
        data = [[[NSData alloc] initWithBytes:bytes length:length] autorelease_stub];
    }
#endif
    return data;
}

- (NSData *)getDataFromBase64URL {
    NSData *data = nil;
#if MS_SDK_REQUIREMENTS
    if (_result) {
        int length;
        char *bytes = ms_result_get_data_b64(_result, &length);
        data = [[[NSData alloc] initWithBytes:bytes length:length] autorelease_stub];
        free(bytes);
    }
#endif
    return data;
}


+ (NSData *)dataFromBase64URLString:(NSString *)string {
    NSData *data = nil;
#if MS_SDK_REQUIREMENTS
    const char *str = [string cStringUsingEncoding:NSASCIIStringEncoding];
    MSResult *r = [[MSResult alloc] initWithBytes:str length:[string length] type:MS_RESULT_TYPE_NONE];
    data = [r getDataFromBase64URL];
    [r release_stub];
#endif
    return data;
}

- (MSResultType)getType {
    ms_result_type type = MS_RESULT_TYPE_NONE;
#if MS_SDK_REQUIREMENTS
    if (_result)
        type = ms_result_get_type(_result);
#endif
    return type;
}

- (BOOL)isEqualToResult:(MSResult *)result {
#if MS_SDK_REQUIREMENTS
    return ms_result_cmp(_result, [result handle]) == 0 ? YES : NO;
#else
    return NO;
#endif
}

- (void)dealloc {
#if MS_SDK_REQUIREMENTS
    if (_result)
        ms_result_del(_result);
#endif
    _result = NULL;

#if ! __has_feature(objc_arc)
    [super dealloc];
#endif
}

- (id)copyWithZone:(NSZone *)zone {
#if MS_SDK_REQUIREMENTS
    const char *bytes = NULL;
    int length;
    ms_result_get_data(_result, &bytes, &length);
    ms_result_type type = ms_result_get_type(_result);
    return [[MSResult allocWithZone:zone] initWithBytes:bytes
                                                 length:length
                                                   type:type];
#else
    return nil;
#endif
}

@end
