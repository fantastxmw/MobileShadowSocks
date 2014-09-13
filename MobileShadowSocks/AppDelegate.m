//
//  AppDelegate.m
//  MobileShadowSocks
//
//  Created by Linus Yang on 13-1-31.
//  Copyright (c) 2013 Linus Yang. All rights reserved.
//

#import "AppDelegate.h"

@implementation AppDelegate

@synthesize window = _window;

+ (BOOL)isLegacySystem
{
    static BOOL isLegacySystem = NO;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        isLegacySystem = SYSTEM_VERSION_LESS_THAN(@"5.0");
    });
    return isLegacySystem;
}

+ (BOOL)isScottForstall
{
    static BOOL isScott = NO;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        isScott = SYSTEM_VERSION_LESS_THAN(@"7.0");
    });
    return isScott;
}

- (void)dealloc
{
    [_window release];
    [_navController release];
    [_tabViewController release];
    [super dealloc];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    if (!SYSTEM_VERSION_LESS_THAN(@"8.0")) {
        UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeBadge categories:nil];
        [[UIApplication sharedApplication] registerUserNotificationSettings:settings];
    }
    self.window = [[[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]] autorelease];
    _tabViewController = [[SettingTableViewController alloc] initWithStyle:UITableViewStyleGrouped];
    _navController = [[UINavigationController alloc] initWithRootViewController:_tabViewController];
    [self.window setRootViewController:_navController];
    [self.window makeKeyAndVisible];
    return YES;
}

- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url
{
    [_tabViewController scannerDidGetResult:[url absoluteString] willDismiss:NO];
    return YES;
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    [_tabViewController fixProxy];
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    [_tabViewController updateProxy];
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    [[NSUserDefaults standardUserDefaults] synchronize];
}

@end
