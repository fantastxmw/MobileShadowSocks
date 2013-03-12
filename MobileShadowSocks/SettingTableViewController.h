//
//  SettingTableViewController.h
//  MobileShadowSocks
//
//  Created by Linus Yang on 13-1-31.
//  Copyright (c) 2013 Linus Yang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ShadowUtility.h"

@interface SettingTableViewController : UITableViewController <UITextFieldDelegate> {
    ShadowUtility *_utility;
    CGFloat _cellWidth;
    NSInteger _tableSectionNumber;
    NSArray *_tableRowNumber;
    NSArray *_tableSectionTitle;
    NSArray *_tableElements;
    NSInteger _tagNumber;
    NSInteger _pacFileCellTag;
    NSInteger _autoProxyCellTag;
    NSMutableArray *_tagKey;
    NSMutableArray *_tagAlwaysEnabled;
    BOOL _isRunning;
    BOOL _isLaunched;
}

- (void)fixProxy;

@end
