//
//  ShadowUtility.m
//  MobileShadowSocks
//
//  Created by Linus Yang on 13-3-4.
//  Copyright (c) 2013 Linus Yang. All rights reserved.
//

#import "ShadowUtility.h"

@implementation ShadowUtility

- (id)initWithPacUrl:(NSString *)url
{
    self = [super init];
    if (self && url) {
        if (getuid() != 0)
            setuid(0);
        _pacUrl = [[NSString alloc] initWithString:url];
    }
    return self;
}

- (void)dealloc
{
    [_pacUrl release];
    [super dealloc];
}

- (BOOL)setProxy:(ProxyStatus)status
{
    BOOL isEnabled;
    BOOL socks;
    BOOL ret;
    isEnabled = socks = NO;
    switch (status) {
        case kProxyPac:
            isEnabled = YES;
            break;
        case kProxySocks:
            isEnabled = socks = YES;
            break;
        default:
            break;
    }
    ret = NO;
    SCDynamicStoreRef store = SCDynamicStoreCreate(0, STORE_ID, 0, 0);
    CFArrayRef list = SCDynamicStoreCopyKeyList(store, SC_IDENTI);
    NSMutableSet *set = [NSMutableSet set];
    int i, j, len;
    for (NSString *state in (NSArray *) list) {
        const char *s = [state cStringUsingEncoding:NSUTF8StringEncoding];
        len = (int) ([state length] - 35);
        for (i = 0; i < len; i++) {
            for (j = i; j - i < 36; j++) {
                if (j - i ==  8 || j - i == 13 || 
                    j - i == 18 || j - i == 23) {
                    if (s[j] != '-')
                        break;
                }
                else if (!((s[j] >= 'A' && s[j] <= 'Z') ||
                           (s[j] >= '0' && s[j] <= '9')))
                    break;
            }
            if (j - i == 36)
                [set addObject:[state substringWithRange:NSMakeRange(i, 36)]];
        }
    }
    NSArray *interfaces = [set allObjects];
    SCPreferencesRef pref = SCPreferencesCreate(0, STORE_ID, 0);
    if ([interfaces count] > 0) {
        NSMutableArray *exceptArray = [NSMutableArray array];
        NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:PREF_FILE];
        NSString *excepts = (NSString *) [dict objectForKey:@"EXCEPTION_LIST"];
        NSArray *origArray = [excepts componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@", "]];
        for (NSString *s in origArray)
            if (![s isEqualToString:@""])
                [exceptArray addObject:s];
        NSMutableDictionary *proxySet = [NSMutableDictionary dictionary];
        if (isEnabled) {
            if ([exceptArray count] > 0)
                [proxySet setObject:exceptArray forKey:@"ExceptionsList"];
            if (socks) {
                [proxySet setObject:[NSNumber numberWithInt:1] forKey:@"SOCKSEnable"];
                [proxySet setObject:@"127.0.0.1" forKey:@"SOCKSProxy"];
                [proxySet setObject:[NSNumber numberWithInt:LOCAL_PORT] forKey:@"SOCKSPort"];
            }
            else {
                [proxySet setObject:[NSNumber numberWithInt:0] forKey:@"HTTPEnable"];
                [proxySet setObject:[NSNumber numberWithInt:2] forKey:@"HTTPProxyType"];
                [proxySet setObject:[NSNumber numberWithInt:0] forKey:@"HTTPSEnable"];
                [proxySet setObject:[NSNumber numberWithInt:1] forKey:@"ProxyAutoConfigEnable"];
                [proxySet setObject:_pacUrl forKey:@"ProxyAutoConfigURLString"];
            }
        }
        else {
            [proxySet setObject:[NSNumber numberWithInt:0] forKey:@"HTTPEnable"];
            [proxySet setObject:[NSNumber numberWithInt:0] forKey:@"HTTPProxyType"];
            [proxySet setObject:[NSNumber numberWithInt:0] forKey:@"HTTPSEnable"];
            [proxySet setObject:[NSNumber numberWithInt:0] forKey:@"ProxyAutoConfigEnable"];
        }
        ret = YES;
        for (NSString *networkid in interfaces)
            ret &= SCPreferencesPathSetValue(pref, (CFStringRef) [NSString stringWithFormat:@"/NetworkServices/%@/Proxies", networkid], (CFDictionaryRef) proxySet);
        ret &= SCPreferencesCommitChanges(pref);
        ret &= SCPreferencesApplyChanges(pref);
        SCPreferencesSynchronize(pref);
    }
    CFRelease(pref);
    CFRelease(list);
    CFRelease(store);
    return ret;
}

@end
