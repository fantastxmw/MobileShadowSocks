//
//  SettingTableViewController.h
//  MobileShadowSocks
//
//  Created by Linus Yang on 13-1-31.
//  Copyright (c) 2013 Linus Yang. All rights reserved.
//

#import <UIKit/UIKit.h>

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
    NSString *_pacURL;
    NSString *_configPath;
    NSString *_pacDefaultFile;
    NSInteger _currentProfile;
    NSMutableDictionary *_textFields;
    NSMutableDictionary *_switchers;
    BOOL _isEnabled;
    BOOL _isPrefChanged;
}

- (void)fixProxy;
- (void)setPrefChanged;
- (void)notifyChanged;
- (void)saveSettings;

- (NSInteger)currentProfile;
- (NSInteger)profileListCount;
- (NSString *)nameOfProfile:(NSInteger)index;
- (void)selectProfile:(NSInteger)profileIndex;
- (void)removeProfile:(NSInteger)profileIndex;

- (void)saveObject:(id)value forKey:(NSString *)key;
- (id)readObject:(NSString *)key;

@end
