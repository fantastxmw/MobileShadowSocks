//
//  ShadowUtility.h
//  MobileShadowSocks
//
//  Created by Linus Yang on 13-3-4.
//  Copyright (c) 2013 Linus Yang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "libshadow/Constant.h"

typedef enum {kProxyPac, kProxySocks, kProxyNone} ProxyStatus;

@interface ShadowUtility : NSObject {
    NSString *_pacUrl;
}

- (id)initWithPacUrl:(NSString *)url;
- (BOOL)setProxy:(ProxyStatus)status;

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
CFArrayRef SCDynamicStoreCopyKeyList (SCDynamicStoreRef store, CFStringRef pattern);
Boolean SCPreferencesPathSetValue (SCPreferencesRef prefs, CFStringRef path, CFDictionaryRef value);
Boolean SCPreferencesCommitChanges (SCPreferencesRef prefs);
Boolean SCPreferencesApplyChanges (SCPreferencesRef prefs);
void SCPreferencesSynchronize (SCPreferencesRef prefs);