//
//  SettingTableViewController.h
//  MobileShadowSocks
//
//  Created by Linus Yang on 13-1-31.
//  Copyright (c) 2013 Linus Yang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CodeScannerViewController.h"

#define LOCAL_PORT 1983
#define PAC_PORT 1993
#define LOCAL_TIMEOUT 60

@protocol SettingTableViewControllerDelegate <NSObject>

- (void)showError:(NSString *)error;
- (void)setBadge:(BOOL)enabled;
- (void)setProxySwitcher:(BOOL)enabled;
- (void)setAutoProxySwitcher:(BOOL)enabled;
- (void)checkFileNotFound;

@end

@interface SettingTableViewController : UITableViewController <UITextFieldDelegate, UIAlertViewDelegate, UIActionSheetDelegate, CodeScannerDelegate, SettingTableViewControllerDelegate> {
    CGFloat _cellWidth;
    NSInteger _tableSectionNumber;
    NSArray *_tableRowNumber;
    NSArray *_tableSectionTitle;
    NSArray *_tableElements;
    NSInteger _tagNumber;
    NSInteger _pacFileCellTag;
    NSInteger _autoProxyCellTag;
    NSInteger _enableCellTag;
    NSMutableDictionary *_tagKey;
    NSString *_pacDefaultFile;
    BOOL _isBuggyPhotoPicker;
}

- (void)fixProxy;
- (void)updateProxy;

@end
