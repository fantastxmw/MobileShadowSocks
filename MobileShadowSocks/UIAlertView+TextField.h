//
//  UIAlertView+TextField.h
//  MobileShadowSocks
//
//  Created by Linus Yang on 14-3-12.
//  Copyright (c) 2014 Linus Yang. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIAlertView (Legacy)

- (void)addTextFieldWithValue:(NSString *)value label:(NSString *)label;
- (UITextField *)textFieldAtIndex:(NSInteger)textFieldIndex;

@end

@interface UIAlertView (TextField)

- (UITextField *)textFieldAtFirstIndex;
- (UITextField *)textFieldInitAtFirstIndex;

@end
