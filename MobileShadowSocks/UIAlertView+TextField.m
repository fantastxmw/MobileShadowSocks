//
//  UIAlertView+TextField.m
//  MobileShadowSocks
//
//  Created by Linus Yang on 14-3-12.
//  Copyright (c) 2014 Linus Yang. All rights reserved.
//

#import "UIAlertView+TextField.h"
#import "AppDelegate.h"

@implementation UIAlertView (TextField)

- (UITextField *)textFieldAtFirstIndex
{
    return [self textFieldWillInit:NO];
}

- (UITextField *)textFieldInitAtFirstIndex
{
    return [self textFieldWillInit:YES];
}

- (UITextField *)textFieldWillInit:(BOOL)willInit
{
    UITextField *textField = nil;
    if ([AppDelegate isLegacySystem]) {
        if (willInit) {
            if ([self respondsToSelector:@selector(addTextFieldWithValue:label:)]) {
                [self addTextFieldWithValue:@"" label:@""];
            }
        }
        if ([self respondsToSelector:@selector(textFieldAtIndex:)]) {
            textField = [self textFieldAtIndex:0];
        }
    } else {
        if (willInit) {
            [self setAlertViewStyle:UIAlertViewStylePlainTextInput];
        }
        textField = [self textFieldAtIndex:0];
    }
    return textField;
}

@end
