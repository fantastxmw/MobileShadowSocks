//
//  ProfileViewController.h
//  MobileShadowSocks
//
//  Created by Linus Yang on 13-12-27.
//  Copyright (c) 2013 Linus Yang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SettingTableViewController.h"

@interface ProfileViewController : UITableViewController <UIAlertViewDelegate> {
    NSInteger _selectedIndex;
}

- (id)initWithStyle:(UITableViewStyle)style;

@end
