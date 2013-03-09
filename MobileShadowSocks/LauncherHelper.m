//
//  LauncherHelper.m
//  MobileShadowSocks
//
//  Created by Linus Yang on 13-3-4.
//  Copyright (c) 2013 Linus Yang. All rights reserved.
//

#import "LauncherHelper.h"

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

- (id)runNetworkConfig:(NSString *)command willGetIdentifiers:(BOOL)enabled
{
    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath:SC_UTIL];
    NSPipe *inPipe = [NSPipe pipe];
    NSPipe *outPipe = [NSPipe pipe];
    NSData *inData = [command dataUsingEncoding:NSUTF8StringEncoding];
    [task setStandardInput:inPipe];
    [task setStandardOutput:outPipe];
    [task setStandardError:[NSFileHandle fileHandleWithNullDevice]];
    @try {
        [task launch];
    }
    @catch (NSException *e) {
        [task release];
        return nil;
    }
    [[inPipe fileHandleForWriting] writeData:inData];
    [[inPipe fileHandleForWriting] closeFile];
    [task waitUntilExit];
    id result = nil;
    if ([task terminationStatus] == 0) {
        NSData *data = [[outPipe fileHandleForReading] readDataToEndOfFile];
        if ([data length] != 0) {
            NSString *dataString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            if (!enabled)
                result = (NSString *) [NSString stringWithString:dataString];
            else {
                result = (NSMutableArray *) [NSMutableArray array];
                const char *s = [dataString UTF8String];
                int len = (int) ([dataString length] - 35);
                int i, j;
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
                        [result addObject:[dataString substringWithRange:NSMakeRange(i, 36)]];
                }
            }
            [dataString release];
        }
        else
            result = @"";
        [[outPipe fileHandleForReading] closeFile];
    }
    [task release];
    return result;
}

- (NSInteger)runProxySetting:(BOOL)isEnabled
{
    NSInteger result = 1;
    NSArray *origArray = [self runNetworkConfig:SC_IDENTI willGetIdentifiers:YES];
    NSArray *array = [NSArray array];
    if (origArray)
        array = [[NSSet setWithArray:origArray] allObjects];
    if ([array count] > 0) {
        result = 0;
        for (NSString *str in array) {
            NSMutableString *command = [NSMutableString stringWithString:@"d.init\n"];
            NSMutableDictionary *proxySet = [NSMutableDictionary dictionary];
            if (isEnabled) {
                NSMutableArray *exceptArray = [NSMutableArray array];
                NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:PREF_FILE];
                NSString *excepts = (NSString *) [dict objectForKey:@"EXCEPTION_LIST"];
                NSArray *origArray = [excepts componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@", "]];
                if (origArray) {
                    for (NSString *s in origArray)
                        if (![s isEqualToString:@""])
                            [exceptArray addObject:s];
                    if ([exceptArray count] > 0) {
                        [command appendFormat:@"d.add ExceptionsList * %@\n", [exceptArray componentsJoinedByString:@" "]];
                        [proxySet setObject:exceptArray forKey:@"ExceptionsList"];
                    }
                }
                [command appendString:@"d.add HTTPEnable # 0\n"];
                [command appendString:@"d.add HTTPProxyType # 2\n"];
                [command appendString:@"d.add HTTPSEnable # 0\n"];
                [command appendString:@"d.add ProxyAutoConfigEnable # 1\n"];
                [command appendFormat:@"d.add ProxyAutoConfigURLString %@\n", _pacUrl];
                [proxySet setObject:[NSNumber numberWithInt:0] forKey:@"HTTPEnable"];
                [proxySet setObject:[NSNumber numberWithInt:2] forKey:@"HTTPProxyType"];
                [proxySet setObject:[NSNumber numberWithInt:0] forKey:@"HTTPSEnable"];
                [proxySet setObject:[NSNumber numberWithInt:1] forKey:@"ProxyAutoConfigEnable"];
                [proxySet setObject:_pacUrl forKey:@"ProxyAutoConfigURLString"];
            }
            else {
                [command appendString:@"d.add HTTPEnable # 0\n"];
                [command appendString:@"d.add HTTPProxyType # 0\n"];
                [command appendString:@"d.add HTTPSEnable # 0\n"];
                [command appendString:@"d.add ProxyAutoConfigEnable # 0\n"];
                [proxySet setObject:[NSNumber numberWithInt:0] forKey:@"HTTPEnable"];
                [proxySet setObject:[NSNumber numberWithInt:0] forKey:@"HTTPProxyType"];
                [proxySet setObject:[NSNumber numberWithInt:0] forKey:@"HTTPSEnable"];
                [proxySet setObject:[NSNumber numberWithInt:0] forKey:@"ProxyAutoConfigEnable"];
            }
            [command appendFormat:@"set Setup:/Network/Service/%@/Proxies\n", str];
            if ([self runNetworkConfig:command willGetIdentifiers:NO] == nil)
                result = 1;
            NSMutableDictionary *scRoot = [NSMutableDictionary dictionaryWithContentsOfFile:SC_STORE];
            NSMutableDictionary *netService = [scRoot objectForKey:@"NetworkServices"];
            NSMutableDictionary *netInterface = [netService objectForKey:str];
            [netInterface setObject:proxySet forKey:@"Proxies"];
            [netService setObject:netInterface forKey:str];
            [scRoot setObject:netService forKey:@"NetworkServices"];
            NSOutputStream *plist = [NSOutputStream outputStreamToFileAtPath:SC_STORE append:NO];
            if (plist && scRoot) {
                [plist open];
                NSString *err = nil;
                CFIndex idx = CFPropertyListWriteToStream(scRoot, (CFWriteStreamRef) plist, kCFPropertyListBinaryFormat_v1_0, (CFStringRef *) &err);
                if (idx == 0)
                    result = 1;
                [plist close];
            }
        }
    }
    return result;
}

- (NSInteger)runDaemon:(BOOL)isEnabled
{
    NSDictionary *fileAttr = [[NSFileManager defaultManager] attributesOfItemAtPath:_daemonFile error:nil];
    NSInteger permission = [[fileAttr objectForKey:NSFilePosixPermissions] intValue];
    NSInteger group =[[fileAttr objectForKey:NSFileGroupOwnerAccountID] intValue];
    NSInteger owner =[[fileAttr objectForKey:NSFileOwnerAccountID] intValue];
    NSMutableDictionary *newAttr = [NSMutableDictionary dictionary];
    if (owner != 0)
        [newAttr setObject:[NSNumber numberWithInt:0] forKey:NSFileOwnerAccountID];
    if (group != 0)
        [newAttr setObject:[NSNumber numberWithInt:0] forKey:NSFileGroupOwnerAccountID];
    if (permission != 644)
        [newAttr setObject:[NSNumber numberWithInt:644] forKey:NSFilePosixPermissions];
    if (owner != 0 || group != 0 || permission != 644)
        [[NSFileManager defaultManager] setAttributes:newAttr ofItemAtPath:_daemonFile error:nil];
    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath:LAUNCH_CTL];
    [task setArguments:[NSArray arrayWithObjects:(isEnabled ? @"load" : @"unload"), @"-w", _daemonFile, nil]];
    NSFileHandle *nullFileHandle = [NSFileHandle fileHandleWithNullDevice];
    [task setStandardError:nullFileHandle];
    [task setStandardOutput:nullFileHandle];
    @try {
        [task launch];
    }
    @catch (NSException *e) {
        [task release];
        return 1;
    }
    [task waitUntilExit];
    NSInteger result = [task terminationStatus];
    [task release];
    return result;
}

@end
