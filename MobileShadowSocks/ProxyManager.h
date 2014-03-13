//
//  ProxyManager.h
//  MobileShadowSocks
//
//  Created by Linus Yang on 14-3-12.
//  Copyright (c) 2014 Linus Yang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SettingTableViewController.h"

@interface ProxyManager : NSObject

@property (nonatomic, assign) id<SettingTableViewControllerDelegate> delegate;

- (void)setProxyEnabled:(BOOL)enabled;
- (void)syncAutoProxy;
- (void)syncProxyStatus:(BOOL)isForce;
- (void)forceStopProxyDaemon;

@end
