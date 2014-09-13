//
//  ProxyManager.m
//  MobileShadowSocks
//
//  Created by Linus Yang on 14-3-12.
//  Copyright (c) 2014 Linus Yang. All rights reserved.
//

#import "ProxyManager.h"
#import "ProfileManager.h"

#define MAX_TRYTIMES 3
#define MAX_TIMEOUT 2.0

#define STR2(x) #x
#define STR(x) STR2(x)
#define MESSAGE_URL @"http://127.0.0.1:" STR(PAC_PORT) "/proxy.pac"

#define RESPONSE_SUCC @"Updated."
#define RESPONSE_FAIL @"Failed."

#define HEADER_VALUE @"True"
#define UPDATE_CONF @"Update-Conf"
#define FORCE_STOP @"Force-Stop"
#define SET_PROXY_PAC @"SetProxy-Pac"
#define SET_PROXY_SOCKS @"SetProxy-Socks"
#define SET_PROXY_NONE @"SetProxy-None"

typedef enum {
    kProxyOperationDisableProxy = 0,
    kProxyOperationEnableSocks,
    kProxyOperationEnablePac,
    kProxyOperationUpdateConf,
    kProxyOperationForceStop,
    
    kProxyOperationCount
} ProxyOperation;

typedef enum {
    kProxyOperationSuccess = 0,
    kProxyOperationError
} ProxyOperationStatus;

@implementation ProxyManager

- (void)dealloc
{
    _delegate = nil;
    [super dealloc];
}

#pragma mark - Private methods

- (void)_setProxyEnabled:(BOOL)enabled showAlert:(BOOL)showAlert updateConf:(BOOL)isUpdateConf
{
    // Set default operation
    ProxyOperation op = kProxyOperationDisableProxy;
    
    BOOL isAutoProxy = [[ProfileManager sharedProfileManager] readBool:kProfileAutoProxy];
    
    // Check if enabling proxy
    if (enabled) {
        // Check if auto proxy is enabled
        if (isAutoProxy) {
            // Show alert if Pac file not found
            if (showAlert) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.delegate checkFileNotFound];
                });
            }
            
            // Set operation to Pac
            op = kProxyOperationEnablePac;
        } else {
            // Set operation to Socks
            op = kProxyOperationEnableSocks;
        }

        // Update config only if proxy enabled
        if (isUpdateConf) {
            static BOOL firstUpdate = YES;
            static dispatch_once_t onceToken;
            
            // Only update when changed, except first time
            [self _sendProxyOperation:kProxyOperationUpdateConf updateOnlyChanged:!firstUpdate];
            dispatch_once(&onceToken, ^{
                firstUpdate = NO;
            });
        }
    }
    
    // Execute proxy operation
    ProxyOperationStatus status = [self _sendProxyOperation:op];
    
    // Show alert when error
    if (status == kProxyOperationError) {
        ProxyOperation currentOp = [self _currentProxyOperation];
        isAutoProxy = (currentOp == kProxyOperationEnablePac);
        enabled = (currentOp == kProxyOperationEnablePac || currentOp == kProxyOperationEnableSocks);

        // Sync auto proxy settings
        [[ProfileManager sharedProfileManager] saveBool:isAutoProxy forKey:kProfileAutoProxy];

        // Alert error
        if (showAlert) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.delegate showError:NSLocalizedString(@"Failed to change proxy settings.\nMaybe no network access available.", nil)];
            });
        }
    }
    
    // save enable status
    [[ProfileManager sharedProfileManager] saveBool:enabled forKey:GLOBAL_PROXY_ENABLE_KEY];
    
    // Update UI
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.delegate setBadge:enabled];
        [self.delegate setProxySwitcher:enabled];
        [self.delegate setAutoProxySwitcher:isAutoProxy];
    });
}

- (ProxyOperationStatus)_sendProxyOperation:(ProxyOperation)op
{
    return [self _sendProxyOperation:op updateOnlyChanged:NO];
}

- (ProxyOperationStatus)_sendProxyOperation:(ProxyOperation)op updateOnlyChanged:(BOOL)updateOnlyChanged
{
    ProxyOperationStatus ret = kProxyOperationError;
    NSString *messageHeader;
    
    // Get HTTP header field of operation
    switch (op) {
        case kProxyOperationUpdateConf:
            messageHeader = UPDATE_CONF;
            break;
        case kProxyOperationDisableProxy:
            messageHeader = SET_PROXY_NONE;
            break;
        case kProxyOperationEnableSocks:
            messageHeader = SET_PROXY_SOCKS;
            break;
        case kProxyOperationEnablePac:
            messageHeader = SET_PROXY_PAC;
            break;
        case kProxyOperationForceStop:
            messageHeader = FORCE_STOP;
            break;
        default:
            messageHeader = SET_PROXY_NONE;
            break;
    }
    
    // Sync config file
    BOOL isChanged = [[ProfileManager sharedProfileManager] syncSettings];

    // Update config only if file changed
    if (updateOnlyChanged && op == kProxyOperationUpdateConf && !isChanged) {
        return kProxyOperationSuccess;
    }
    
    // Init HTTP request
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:MESSAGE_URL]];
    [request setValue:HEADER_VALUE forHTTPHeaderField:messageHeader];
    [request setTimeoutInterval:MAX_TIMEOUT];
    
    // Try send request
    int i;
    for (i = 0; i < MAX_TRYTIMES; i++) {
        
        // Get response data
        NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil];
        
        // Continue if no response
        if (data == nil) {
            continue;
        }
        
        NSString *str = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
        
        // Parse response
        if ([str hasPrefix:RESPONSE_SUCC]) {
            ret = kProxyOperationSuccess;
            break;
        } else if ([str hasPrefix:RESPONSE_FAIL]) {
            ret = kProxyOperationError;
            break;
        }
    }
    
    return ret;
}

- (ProxyOperation)_currentProxyOperation
{
    // Copy current status settings
    CFDictionaryRef proxyDict = CFNetworkCopySystemProxySettings();
    
    // Check if pac auto proxy enabled
    BOOL pacEnabled = [[(NSDictionary *) proxyDict objectForKey:@"ProxyAutoConfigEnable"] boolValue];
    
    // Check if socks proxy enabled
    BOOL socksEnabled = [[(NSDictionary *) proxyDict objectForKey:@"SOCKSEnable"] boolValue];
    
    // Determine current proxy operation
    ProxyOperation currentOp = kProxyOperationDisableProxy;
    if (pacEnabled) {
        currentOp = kProxyOperationEnablePac;
    } else if (socksEnabled) {
        currentOp = kProxyOperationEnableSocks;
    }
    
    // Clean up
    CFRelease(proxyDict);
    
    return currentOp;
}

- (BOOL)_prefProxyEnabled
{
    return [[ProfileManager sharedProfileManager] readBool:GLOBAL_PROXY_ENABLE_KEY];
}

#pragma marks - Public methods

- (void)setProxyEnabled:(BOOL)enabled
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self _setProxyEnabled:enabled showAlert:YES updateConf:YES];
    });
}

- (void)syncAutoProxy
{
    // Change proxy only if proxy is enabled
    if ([self _prefProxyEnabled]) {
        [self setProxyEnabled:YES];
    }
}

- (void)syncProxyStatus:(BOOL)isForce
{
    BOOL prefEnabled = [self _prefProxyEnabled];
    
    // Sync when enabled or trying to proxy
    if (isForce || prefEnabled) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            // No updating config when fixing proxy
            [self _setProxyEnabled:prefEnabled showAlert:isForce updateConf:!isForce];
        });
    }
}

- (void)forceStopProxyDaemon
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self _sendProxyOperation:kProxyOperationForceStop];
    });
}

@end
