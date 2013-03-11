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

#include "moodstocks_sdk.h"

/**
 * Scanning types as defined in moodstocks_sdk.h:
 *  MS_RESULT_TYPE_EAN8     -> EAN8 linear barcode
 *  MS_RESULT_TYPE_EAN13    -> EAN13 linear barcode
 *  MS_RESULT_TYPE_QRCODE   -> QR Code 2D barcode
 *  MS_RESULT_TYPE_DMTX     -> Datamatrix 2D barcode
 *  MS_RESULT_TYPE_IMAGE    -> Image match
 * These are to be used either as scan options (see `MSScannerSession`)
 * by combining them with bitwise-or, or to hold a kind of result.
 */
typedef ms_result_type MSResultType;

/**
 * Structure holding the result of a scan
 * It is composed of:
 * - its type among those listed in `MSResultType` enum above
 * - its value as a string that may represent:
 *  - an image ID when the type is `MS_RESULT_TYPE_IMAGE`,
 *  - a barcode numbers when the type is `MS_RESULT_TYPE_EAN8`
 *    or `MS_RESULT_TYPE_EAN13`
 *  - raw QR Code data (i.e. *unparsed*) when type is `MS_RESULT_TYPE_QRCODE`
 *    or `MS_RESULT_TYPE_DMTX`
 */
@interface MSResult : NSObject <NSCopying> {
    ms_result_t *_result;
}

@property (nonatomic, readonly) ms_result_t *handle;

- (id)init;
- (id)initWithBytes:(const void *)bytes length:(NSUInteger)length type:(MSResultType)type;
- (id)initWithResult:(const ms_result_t *)result;

/**
 * Return the result as a string with UTF-8 encoding
 * Use `getData` if you intend to create a string with another
 * encoding or just want to interact with the raw bytes
 */
- (NSString *)getValue;

/**
 * Return the result as raw data (byte array)
 */
- (NSData *)getData;

/**
 * Perform base64url without padding decoding on the result
 * bytes (considered as a character string) and return the
 * decoded data
 */
- (NSData *)getDataFromBase64URL;

/**
 * Perform base64url without padding decoding on the input
 * string and return the decoded data
 */
+ (NSData *)dataFromBase64URLString:(NSString *)string;

/**
 * Return the result type
 */
- (MSResultType)getType;

/**
 * Return YES if the current result is strictly the same than
 * the input one, NO otherwise
 */
- (BOOL)isEqualToResult:(MSResult *)result;

/**
 * Clone this result
 */
- (id)copyWithZone:(NSZone *)zone;
@end
