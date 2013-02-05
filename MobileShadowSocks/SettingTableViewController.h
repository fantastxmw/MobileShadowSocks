//
//  SettingTableViewController.h
//  MobileShadowSocks
//
//  Created by Linus Yang on 13-1-31.
//  Copyright (c) 2013 Linus Yang. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SettingTableViewController : UITableViewController <UITextFieldDelegate> {
    BOOL _prefDidChange;
    BOOL _isRunning;
    CGFloat _cellWidth;
}
- (void)startProcess;
- (void)stopProcess;
- (BOOL)writeToPref;
- (void)showAbout;
- (void)showRunCmdError;
- (void)revertProxySettings;
- (void)doAfterRevert;
- (void)hideKeyboard;
- (void)setRunningStatus:(BOOL)isRunning;
- (void)setViewEnabled:(BOOL)isEnabled;
- (void)fixProxy;
- (void)setAutoProxy:(BOOL)isEnabled;

@end
