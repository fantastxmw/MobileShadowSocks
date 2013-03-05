//
//  LauncherHelper.h
//  MobileShadowSocks
//
//  Created by Linus Yang on 13-3-4.
//  Copyright (c) 2013 Linus Yang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <unistd.h>
#import <stdio.h>
#import "Constant.h"

#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
#import "NSTask.h"
#endif

@interface LauncherHelper : NSObject {
    NSString *_daemonFile;
    NSString *_daemonIdentifier;
    NSString *_pacUrl;
}

- (id)initWithDaemonIdentifier:(NSString *)identifier andPacUrl:(NSString *)url;
- (NSInteger)runProxySetting:(BOOL)isEnabled;
- (NSInteger)runDaemon:(BOOL)isEnabled;

@end
