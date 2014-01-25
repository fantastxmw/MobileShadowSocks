//
//  UINavigationController+Orientation.m
//  MobileShadowSocks
//
//  Created by Linus Yang on 14-1-25.
//  Copyright (c) 2014 Linus Yang. All rights reserved.
//

#import "UINavigationController+Orientation.h"

@implementation UINavigationController (Orientation)

- (BOOL)shouldAutorotate
{
    return [self.topViewController shouldAutorotate];
}

- (NSUInteger)supportedInterfaceOrientations
{
    return [self.topViewController supportedInterfaceOrientations];
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
    return [self.topViewController preferredInterfaceOrientationForPresentation];
}

@end
