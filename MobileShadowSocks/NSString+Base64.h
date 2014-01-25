//
//  NSString+Base64.h
//  MobileShadowSocks
//
//  Created by Linus Yang on 14-1-25.
//  Copyright (c) 2014 Linus Yang. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (Base64)

+ (NSString *)stringWithBase64String:(NSString *)string encode:(BOOL)encode;
- (NSString *)base64EncodedString;
- (NSString *)base64DecodedString;

@end
