//
//  SettingTableViewController.h
//  MobileShadowSocks
//
//  Created by Linus Yang on 13-1-31.
//  Copyright (c) 2013 Linus Yang. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SettingTableViewController : UITableViewController <UITextFieldDelegate> {
    BOOL prefDidChange;
    CGFloat cellWidth;
}
- (void)startProcess;
- (void)stopProcess;
- (BOOL)writeToPref;
- (void)showAbout;
- (void)showRunCmdError;
- (void)revertProxySettings;
- (void)hideKeyboard;

@end
