//
//  ShadowUtility.h
//  MobileShadowSocks
//
//  Created by Linus Yang on 13-3-4.
//  Copyright (c) 2013 Linus Yang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NSTask.h"
#import "Constant.h"

@interface ShadowUtility : NSObject {
    NSString *_daemonIdentifier;
    NSString *_launcherPath;
}

- (id)initWithDaemonIdentifier:(NSString *)identifier;
- (BOOL)isRunning;
- (BOOL)setProxy:(BOOL)isEnabled;
- (BOOL)startStopDaemon:(BOOL)start;

@end
