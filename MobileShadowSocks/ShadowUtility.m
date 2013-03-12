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
    CFArrayRef ref = launchctl_list();
    BOOL ret = NO;
    for (NSString *str in (NSArray *) ref)
        if ([str isEqualToString:DAEMON_ID]) {
            ret = YES;
            break;
        }
    CFRelease(ref);
    return ret;
}

- (BOOL)runLauncher:(const char *)arg
{
    BOOL result = NO;
    if ([[NSFileManager defaultManager] isExecutableFileAtPath:_launcherPath]) {
        const char *execs = [_launcherPath cStringUsingEncoding:NSUTF8StringEncoding];
        const char *args[3] = {"launcher", arg, 0};
        pid_t pid;
        pid_t wait_pid;
        int status = 0;
        pid = fork();
        if (pid == 0) {
            execv(execs, (char **) args);
            exit(0);
        }
        else if (pid > 0) {
            wait_pid = waitpid(pid, &status, 0);
            if (wait_pid > 0) {
                result = YES;
                if (WIFEXITED(status) && WEXITSTATUS(status) != 0)
                    result = NO;
            }
        }
    }
    return result;
}

- (BOOL)setProxy:(ProxyStatus)status
{
    switch (status) {
        case kProxyPac:
            return [self runLauncher:"-p"];
        case kProxySocks:
            return [self runLauncher:"-k"];
        default:
            return [self runLauncher:"-n"];
    }
    return NO;
}

- (BOOL)startStopDaemon:(BOOL)start
{
    return [self runLauncher:(start ? "-r" : "-s")];
}

@end
