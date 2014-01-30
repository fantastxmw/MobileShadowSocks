//
//  ImagePickerViewController.m
//  MobileShadowSocks
//
//  Created by Linus Yang on 14-1-30.
//  Copyright (c) 2014 Linus Yang. All rights reserved.
//

#import "ImagePickerViewController.h"

@implementation ImagePickerViewController

- (BOOL)shouldAutorotate
{
    return NO;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
    return UIInterfaceOrientationPortrait;
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskAllButUpsideDown;
}

@end
