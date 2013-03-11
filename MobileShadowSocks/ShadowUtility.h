//
//  ShadowUtility.h
//  MobileShadowSocks
//
//  Created by Linus Yang on 13-3-4.
//  Copyright (c) 2013 Linus Yang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "subprocess.h"
#import "Constant.h"

typedef enum {kProxyPac, kProxySocks, kProxyNone} ProxyStatus;

@interface ShadowUtility : NSObject {
    NSString *_daemonIdentifier;
    NSString *_launcherPath;
}

- (id)initWithDaemonIdentifier:(NSString *)identifier;
- (BOOL)isRunning;
- (BOOL)setProxy:(ProxyStatus)status;
- (BOOL)startStopDaemon:(BOOL)start;

@end
