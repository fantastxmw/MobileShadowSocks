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

- (void)dealloc
{
    [_window release];
    [_navController release];
    [_tabViewController release];
    [super dealloc];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]] autorelease];
    _tabViewController = [[SettingTableViewController alloc] initWithStyle:UITableViewStyleGrouped];
    _navController = [[UINavigationController alloc] initWithRootViewController:_tabViewController];
    [self.window setRootViewController:_navController];
    [self.window makeKeyAndVisible];
    return YES;
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    [_tabViewController fixProxy];
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    [_tabViewController notifyChanged];
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    [_tabViewController saveSettings];
}

@end
