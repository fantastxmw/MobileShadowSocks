//
//  CipherViewController.h
//  MobileShadowSocks
//
//  Created by Linus Yang on 13-5-26.
//  Copyright (c) 2013 Linus Yang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SettingTableViewController.h"

@interface CipherViewController : UITableViewController {
    SettingTableViewController *_parentView;
    NSInteger _cipherNumber;
    NSInteger _selectedCipher;
    NSArray *_cipherNameArray;
    NSArray *_cipherKeyArray;
}

- (id)initWithStyle:(UITableViewStyle)style withParentView:(SettingTableViewController *)parentView;

@end
