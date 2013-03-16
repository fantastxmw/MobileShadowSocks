//
//  LauncherHelper.m
//  MobileShadowSocks
//
//  Created by Linus Yang on 13-3-4.
//  Copyright (c) 2013 Linus Yang. All rights reserved.
//

#import "LauncherHelper.h"
#import <arpa/inet.h>

@implementation LauncherHelper

- (id)initWithDaemonIdentifier:(NSString *)identifier andPacUrl:(NSString *)url
{
    self = [super init];
    if (self && identifier && url) {
        if (getuid() != 0 && setuid(0) == -1)
            fprintf(stderr, "Warning: failed to get root\n");
        _daemonIdentifier = [[NSString alloc] initWithString:identifier];
        _pacUrl = [[NSString alloc] initWithString:url];
        _daemonFile = [[NSString alloc] initWithFormat:@"%@/%@.plist", BUNDLE_PATH, _daemonIdentifier];
    }
    return self;
}

- (void)dealloc
{
    [_daemonIdentifier release];
    [_daemonFile release];
    [_pacUrl release];
    [super dealloc];
}

- (NSInteger)runProxySetting:(BOOL)isEnabled usingSocks:(BOOL)socks
{
    BOOL ret = NO;
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
    return ret ? 0 : 1;
}

- (NSInteger)runDaemon:(BOOL)isEnabled
{
    if (![[NSFileManager defaultManager] fileExistsAtPath:_daemonFile])
        return 1;
    NSDictionary *fileAttr = [[NSFileManager defaultManager] attributesOfItemAtPath:_daemonFile error:nil];
    NSInteger permission = [[fileAttr objectForKey:NSFilePosixPermissions] intValue];
    NSInteger group =[[fileAttr objectForKey:NSFileGroupOwnerAccountID] intValue];
    NSInteger owner =[[fileAttr objectForKey:NSFileOwnerAccountID] intValue];
    NSMutableDictionary *newAttr = [NSMutableDictionary dictionary];
    if (owner != 0)
        [newAttr setObject:[NSNumber numberWithInt:0] forKey:NSFileOwnerAccountID];
    if (group != 0)
        [newAttr setObject:[NSNumber numberWithInt:0] forKey:NSFileGroupOwnerAccountID];
    if (permission != 0644)
        [newAttr setObject:[NSNumber numberWithInt:0644] forKey:NSFilePosixPermissions];
    if (owner != 0 || group != 0 || permission != 0644)
        [[NSFileManager defaultManager] setAttributes:newAttr ofItemAtPath:_daemonFile error:nil];
    NSInteger result = 0;
    if (isEnabled)
        result = launchctl_load_path((CFStringRef) _daemonFile, true, false);
    else
        result = launchctl_unload_path((CFStringRef) _daemonFile, true);
    return result;
}

+ (void)runPacServer
{
    NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
    struct sockaddr_in client;
    struct sockaddr_in server;
    socklen_t socksize = sizeof(struct sockaddr_in);
    int sock;
    int conn;
    int optval = 1;
    char buf[BUFF_SIZE];
    FILE *stream;
    BOOL autoProxy;
    
    memset(&server, 0, sizeof(server));
    server.sin_family = AF_INET;
    server.sin_addr.s_addr = inet_addr("127.0.0.1");
    server.sin_port = htons(PAC_PORT);
    sock = socket(AF_INET, SOCK_STREAM, 0);
    if (sock < 0) {
        fprintf(stderr, "Error: cannot open socket\n");
        [pool release];
        return;
    }
    setsockopt(sock, SOL_SOCKET, SO_REUSEADDR, (const void *)&optval , sizeof(int));
    if (bind(sock, (struct sockaddr *) &server, sizeof(struct sockaddr)) < 0) {
        fprintf(stderr, "Error: cannot bind port\n");
        close(sock);
        [pool release];
        return;
    }
    if (listen(sock, SOMAXCONN) < 0) {
        fprintf(stderr, "Error: cannot listen on port\n");
        close(sock);
        [pool release];
        return;
    }
    while (1) {
        if ([[NSThread currentThread] isCancelled])
            break;
        conn = accept(sock, (struct sockaddr *) &client, &socksize);
        if (conn < 0) {
            fprintf(stderr, "Error: cannot accept\n");
            close(sock);
            [pool release];
            return;
        }
        if (!(stream = fdopen(conn, "r+"))) {
            fprintf(stderr, "Error: cannot open stream\n");
            close(sock);
            [pool release];
            return;
        }
        do {
            fgets(buf, BUFF_SIZE, stream);
        } while (strcmp(buf, "\r\n") && strcmp(buf, "\n"));
        fprintf(stream, HTTP_RESPONSE);
        BOOL sent = NO;
        NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:PREF_FILE];
        if (dict) {
            autoProxy = [[dict objectForKey:@"AUTO_PROXY"] boolValue];
            if (autoProxy) {
                NSString *filePath = [(NSString *) [dict objectForKey:@"PAC_FILE"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                if (filePath && [[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
                    fprintf(stream, "%s", [[NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:nil] cStringUsingEncoding:NSUTF8StringEncoding]);
                    sent = YES;
                }
            }
        }
        if (!sent)
            fprintf(stream, EMPTY_PAC, LOCAL_PORT);
        fflush(stream);
        fclose(stream);
        close(conn);
    }
    close(sock);
    [pool release];
}

@end
