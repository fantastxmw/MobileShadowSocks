/*
 *    ShadowSocks Per-App Proxy Plugin
 *    https://github.com/linusyang/MobileShadowSocks
 *
 *    Copyright (c) 2014 Linus Yang <laokongzi@gmail.com>
 *
 *    This program is free software: you can redistribute it and/or modify
 *    it under the terms of the GNU General Public License as published by
 *    the Free Software Foundation, either version 3 of the License, or
 *    (at your option) any later version.
 *
 *    This program is distributed in the hope that it will be useful,
 *    but WITHOUT ANY WARRANTY; without even the implied warranty of
 *    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *    GNU General Public License for more details.
 *
 *    You should have received a copy of the GNU General Public License
 *    along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 */

#define FUNC_NAME SCDynamicStoreCopyProxies
#define ORIG_FUNC original_ ## FUNC_NAME
#define CUST_FUNC custom_ ## FUNC_NAME

#define DECL_FUNC(ret, ...) \
    extern ret FUNC_NAME(__VA_ARGS__); \
    static ret (*ORIG_FUNC)(__VA_ARGS__); \
    ret CUST_FUNC(__VA_ARGS__)

#define HOOK_FUNC() \
    MSHookFunction(FUNC_NAME, (void *) CUST_FUNC, (void **) &ORIG_FUNC)

typedef const struct __SCDynamicStore *SCDynamicStoreRef;
void MSHookFunction(void *symbol, void *replace, void **result);

static BOOL getValue(NSDictionary *dict, NSString *key, BOOL defaultVal)
{
    if (dict == nil || key == nil) {
        return defaultVal;
    }
    NSNumber *valObj = [dict objectForKey:key];
    if (valObj == nil) {
        return defaultVal;
    }
    return [valObj boolValue];
}

DECL_FUNC(CFDictionaryRef, SCDynamicStoreRef store)
{
    CFMutableDictionaryRef proxyDict = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    int zero = 0;
    CFNumberRef zeroNumber = CFNumberCreate(kCFAllocatorDefault, kCFNumberIntType, &zero);
    CFDictionarySetValue(proxyDict, CFSTR("HTTPEnable"), zeroNumber);
    CFDictionarySetValue(proxyDict, CFSTR("HTTPProxyType"), zeroNumber);
    CFDictionarySetValue(proxyDict, CFSTR("HTTPSEnable"), zeroNumber);
    CFDictionarySetValue(proxyDict, CFSTR("ProxyAutoConfigEnable"), zeroNumber);
    CFRelease(zeroNumber);
    return proxyDict;
}

%group TwitterHook

%hook T1SPDYConfigurationChangeListener 
- (BOOL)_shouldEnableSPDY
{
    return NO;
}
%end

%end

%group FacebookHook

%hook FBRequester
- (BOOL)allowSPDY
{
    return NO;
}

- (BOOL)useDNSCache
{
    return NO;
}
%end

%hook FBNetworkerRequest
- (BOOL)disableSPDY
{
    return YES;
}
%end

%hook FBRequesterState
- (BOOL)didUseSPDY
{
    return NO;
}
%end

%hook FBAppConfigService
- (BOOL)disableDNSCache
{
    return YES;
}
%end

%hook FBNetworker
- (BOOL)_shouldAllowUseOfDNSCache:(id)arg
{
    return NO;
}
%end

%hook FBAppSessionController
- (BOOL)networkerShouldAllowUseOfDNSCache:(id)arg
{
    return NO;
}
%end

%end

%ctor
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NSString *bundleName = [[NSBundle mainBundle] bundleIdentifier];
    if (bundleName != nil &&
        ![bundleName isEqualToString:@"com.linusyang.MobileShadowSocks"] &&
        ![bundleName isEqualToString:@"com.apple.springboard"]) {
        BOOL proxyEnabled = YES;
        BOOL spdyDisabled = YES;
        NSDictionary *dict = [[NSDictionary alloc] initWithContentsOfFile:@"/var/mobile/Library/Preferences/com.linusyang.ssperapp.plist"];
        if (dict != nil) {
            if (getValue(dict, @"SSPerAppEnabled", NO)) {
                NSString *entry = [[NSString alloc] initWithFormat:@"Enabled-%@", bundleName];
                proxyEnabled = getValue(dict, entry, NO);
                if (getValue(dict, @"SSPerAppReversed", NO)) {
                    proxyEnabled = !proxyEnabled;
                }
                [entry release];
            }
            spdyDisabled = getValue(dict, @"SSPerAppDisableSPDY", YES);
            [dict release];
        }
        if (!proxyEnabled) {
            HOOK_FUNC();
        }
        if (spdyDisabled) {
            if ([bundleName isEqualToString:@"com.atebits.Tweetie2"]) {
                %init(TwitterHook);
            } else if ([bundleName isEqualToString:@"com.facebook.Facebook"]) {
                %init(FacebookHook);
            }
        }
    }
    [pool drain];
}
