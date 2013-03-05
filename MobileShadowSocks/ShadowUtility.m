//
//  ShadowUtility.m
//  MobileShadowSocks
//
//  Created by Linus Yang on 13-3-4.
//  Copyright (c) 2013 Linus Yang. All rights reserved.
//

#import "ShadowUtility.h"

@implementation ShadowUtility

- (id)initWithDaemonIdentifier:(NSString *)identifier
{
    self = [super init];
    if (self && identifier) {
        _daemonIdentifier = [[NSString alloc] initWithString:identifier];
        _launcherPath = [[NSString alloc] initWithFormat:@"%@/launcher", [[NSBundle mainBundle] bundlePath]];
    }
    return self;
}

- (void)dealloc
{
    [_daemonIdentifier release];
    [_launcherPath release];
    [super dealloc];
}

- (BOOL)isRunning
{
    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath:LAUNCH_CTL];
    [task setArguments:[NSArray arrayWithObjects:@"list", nil]];
    NSPipe *pipe = [NSPipe pipe];
    [task setStandardError:[NSFileHandle fileHandleWithNullDevice]];
    [task setStandardOutput:pipe];
    @try {
        [task launch];
    }
    @catch (NSException *e) {
        [task release];
        return NO;
    }
    [task waitUntilExit];
    BOOL result = NO;
    if ([task terminationStatus] == 0) {
        NSData *data = [[pipe fileHandleForReading] readDataToEndOfFile];
        if ([data length] != 0) {
            NSString *dataString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            if ([dataString rangeOfString:_daemonIdentifier].location != NSNotFound)
                result = YES;
            [dataString release];
        }
        [[pipe fileHandleForReading] closeFile];
    }
    [task release];
    return result;
}

- (BOOL)runLauncher:(BOOL)enabled withFirst:(NSString *)arg1 andSecond:(NSString *)arg2
{
    BOOL result = NO;
    if ([[NSFileManager defaultManager] isExecutableFileAtPath:_launcherPath]) {
        NSTask *task = [[NSTask alloc] init];
        [task setLaunchPath:_launcherPath];
        [task setArguments:[NSArray arrayWithObjects:(enabled ? arg1 : arg2), nil]];
        NSFileHandle *nullFileHandle = [NSFileHandle fileHandleWithNullDevice];
        [task setStandardError:nullFileHandle];
        [task setStandardOutput:nullFileHandle];
        [task launch];
        [task waitUntilExit];
        result = [task terminationStatus] ? NO : YES;
        [task release];
    }
    return result;
}

- (BOOL)setProxy:(BOOL)isEnabled
{
    return [self runLauncher:isEnabled withFirst:@"-p" andSecond:@"-n"];
}

- (BOOL)startStopDaemon:(BOOL)start
{
    BOOL result = [self runLauncher:start withFirst:@"-r" andSecond:@"-s"];
    if (start != [self isRunning])
        result = NO;
    return result;
}

@end
