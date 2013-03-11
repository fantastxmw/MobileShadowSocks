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
#import "subprocess.h"

@interface LauncherHelper : NSObject {
    NSString *_daemonFile;
    NSString *_daemonIdentifier;
    NSString *_pacUrl;
}

- (id)initWithDaemonIdentifier:(NSString *)identifier andPacUrl:(NSString *)url;
- (NSInteger)runProxySetting:(BOOL)isEnabled usingSocks:(BOOL)socks;
- (NSInteger)runDaemon:(BOOL)isEnabled;

@end
