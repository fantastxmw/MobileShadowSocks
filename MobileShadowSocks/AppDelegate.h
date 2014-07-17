//
//  AppDelegate.h
//  MobileShadowSocks
//
//  Created by Linus Yang on 13-1-31.
//  Copyright (c) 2013 Linus Yang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SettingTableViewController.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate> {
    UINavigationController *_navController;
    SettingTableViewController *_tabViewController;
}

@property (nonatomic, retain) UIWindow *window;

+ (BOOL)isLegacySystem;
+ (BOOL)isScottForstall;

@end
