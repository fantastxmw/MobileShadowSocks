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
    [navController release];
    [tabViewController release];
    [super dealloc];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]] autorelease];
    tabViewController = [[SettingTableViewController alloc] initWithStyle:UITableViewStyleGrouped];
    navController = [[UINavigationController alloc] initWithRootViewController:tabViewController];
    [self.window addSubview:[navController view]];
    [self.window makeKeyAndVisible];
    return YES;
}

@end
