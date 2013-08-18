//
//  SettingTableViewController.h
//  MobileShadowSocks
//
//  Created by Linus Yang on 13-1-31.
//  Copyright (c) 2013 Linus Yang. All rights reserved.
//

#import <UIKit/UIKit.h>

#define PROXY_PAC_STATUS 3
#define PROXY_SOCKS_STATUS 2
#define PROXY_NONE_STATUS 1

typedef enum {kProxyPac, kProxySocks, kProxyNone} ProxyStatus;

@interface SettingTableViewController : UITableViewController <UITextFieldDelegate> {
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
    NSMutableArray *_tagWillNotifyChange;
    NSString *_pacURL;
    BOOL _isEnabled;
    BOOL _isPrefChanged;
}

- (void)fixProxy;
- (BOOL)setProxy:(ProxyStatus)status;
- (void)setPrefChanged;
- (void)notifyChanged;
- (void)notifyChangedWhenRunning;

@end
