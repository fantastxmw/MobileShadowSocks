//
//  UIView+UserInfo.m
//  MobileShadowSocks
//
//  Created by Linus Yang on 14-7-14.
//  Copyright (c) 2014 Linus Yang. All rights reserved.
//

#import "UIView+UserInfo.h"
#import <objc/runtime.h>

static const void *UIViewUserInfoKey = &UIViewUserInfoKey;

@implementation UIView (UserInfo)

- (id)userInfo
{
    return objc_getAssociatedObject(self, UIViewUserInfoKey);
}

- (void)setUserInfo:(id)userInfo
{
    objc_setAssociatedObject(self, UIViewUserInfoKey, userInfo, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
