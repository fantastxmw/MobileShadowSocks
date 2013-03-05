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
            result = (NSString *) [NSString stringWithString:@""];
        [[outPipe fileHandleForReading] closeFile];
    }
    [task release];
    return result;
}

- (NSInteger)runProxySetting:(BOOL)isEnabled
{
    NSInteger result = 1;
    NSArray *array = [self runNetworkConfig:SC_IDENTI willGetIdentifiers:YES];
    if (array) {
        result = 0;
        for (NSString *str in array) {
            NSMutableString *command = [NSMutableString stringWithString:@"d.init\n"];
            if (isEnabled) {
                NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:PREF_FILE];
                if (dict) {
                    NSString *excepts = (NSString *) [dict objectForKey:@"EXCEPTION_LIST"];
                    if (excepts) {
                        NSArray *origArray = [excepts componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@", "]];
                        NSMutableArray *array = [NSMutableArray array];
                        for (NSString *str in origArray)
                            if (![str isEqualToString:@""])
                                [array addObject:str];
                        if ([array count] > 0)
                            [command appendFormat:@"d.add ExceptionsList * %@\n", [array componentsJoinedByString:@" "]];
                    }
                }
                [command appendString:@"d.add HTTPEnable # 0\n"];
                [command appendString:@"d.add HTTPProxyType # 2\n"];
                [command appendString:@"d.add HTTPSEnable # 0\n"];
                [command appendString:@"d.add ProxyAutoConfigEnable # 1\n"];
                [command appendFormat:@"d.add ProxyAutoConfigURLString %@\n", _pacUrl];
                
            }
            else {
                [command appendString:@"d.add HTTPEnable # 0\n"];
                [command appendString:@"d.add HTTPProxyType # 0\n"];
                [command appendString:@"d.add HTTPSEnable # 0\n"];
                [command appendString:@"d.add ProxyAutoConfigEnable # 0\n"];
            }
            [command appendFormat:@"set Setup:/Network/Service/%@/Proxies\n", str];
            if ([self runNetworkConfig:command willGetIdentifiers:NO] == nil)
                result = 1;
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
