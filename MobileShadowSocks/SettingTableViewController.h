//
//  SettingTableViewController.h
//  MobileShadowSocks
//
//  Created by Linus Yang on 13-1-31.
//  Copyright (c) 2013 Linus Yang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "libshadow/Constant.h"

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
    NSMutableArray *_tagKey;
    NSMutableArray *_tagWillNotifyChange;
    NSString *_pacURL;
    BOOL _isLaunched;
    BOOL _isEnabled;
    BOOL _isPrefChanged;
}

- (void)fixProxy;
- (BOOL)setProxy:(ProxyStatus)status;
- (void)notifyChanged;
- (void)setBadge;

@end

typedef const struct __SCPreferences *  SCPreferencesRef;
SCPreferencesRef SCPreferencesCreate (CFAllocatorRef allocator, CFStringRef name, CFStringRef prefsID);
typedef const struct __SCDynamicStore * SCDynamicStoreRef;
typedef void (*SCDynamicStoreCallBack) (SCDynamicStoreRef store, CFArrayRef changedKeys, void *info);
typedef struct {
    CFIndex     version;
    void *      info;
    const void  *(*retain)(const void *info);
    void        (*release)(const void *info);
    CFStringRef (*copyDescription)(const void *info);
} SCDynamicStoreContext;
SCDynamicStoreRef SCDynamicStoreCreate (CFAllocatorRef allocator, CFStringRef name, SCDynamicStoreCallBack callout, SCDynamicStoreContext *context);
CFPropertyListRef SCPreferencesGetValue(SCPreferencesRef prefs, CFStringRef key);
Boolean SCPreferencesPathSetValue (SCPreferencesRef prefs, CFStringRef path, CFDictionaryRef value);
Boolean SCPreferencesCommitChanges (SCPreferencesRef prefs);
Boolean SCPreferencesApplyChanges (SCPreferencesRef prefs);
void SCPreferencesSynchronize (SCPreferencesRef prefs);
