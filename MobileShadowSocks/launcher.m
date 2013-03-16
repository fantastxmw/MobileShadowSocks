//
//  launcher.m
//  MobileShadowSocks Launcher
//
//  Created by Linus Yang on 13-3-4.
//  Copyright (c) 2013 Linus Yang. All rights reserved.
//

#import "LauncherHelper.h"
#import "build_time.h"
#import "libshadow/local.h"

int main(int argc, const char **argv)
{
    @autoreleasepool {
        if (argc > 1) {
            if (argc != 2 || argv[1][0] != '-' || !argv[1][1] || argv[1][2]) {
                fprintf(stderr, USAGE_STR, BUILDTIME, argv[0]);
                exit(1);
            }
            LauncherHelper *helper = [[LauncherHelper alloc] initWithDaemonIdentifier:DAEMON_ID andPacUrl:[NSString stringWithFormat:@"http://127.0.0.1:%d/shadow.pac", PAC_PORT]];
            NSInteger result = 0;
            switch (argv[1][1]) {
                case 'r':
                    result = [helper runDaemon:YES];
                    break;
                case 's':
                    result = [helper runDaemon:NO];
                    break;
                case 'p':
                    result = [helper runProxySetting:YES usingSocks:NO];
                    break;
                case 'n':
                    result = [helper runProxySetting:NO usingSocks:NO];
                    break;
                case 'k':
                    result = [helper runProxySetting:YES usingSocks:YES];
                    break;
                default:
                    fprintf(stderr, USAGE_STR, BUILDTIME, argv[0]);
                    result = 1;
                    break;
            }
            [helper release];
            exit(result);
        }
        NSDictionary *prefDict = [NSDictionary dictionaryWithContentsOfFile:PREF_FILE];
        if (prefDict) {
            NSString *remoteServer = (NSString *) [prefDict objectForKey:@"REMOTE_SERVER"];
            NSString *remotePort = (NSString *) [prefDict objectForKey:@"REMOTE_PORT"];
            NSString *socksPass = (NSString *) [prefDict objectForKey:@"SOCKS_PASS"];
            BOOL useCrypto = [[prefDict objectForKey:@"USE_RC4"] boolValue];
            NSMutableArray *arguments = [NSMutableArray array];
            [arguments addObject:@"-s"];
            if (remoteServer)
                [arguments addObject:remoteServer];
            else
                [arguments addObject:@"127.0.0.1"];
            [arguments addObject:@"-p"];
            if (remotePort)
                [arguments addObject:remotePort];
            else
                [arguments addObject:@"8080"];
            [arguments addObject:@"-l"];
            [arguments addObject:[NSString stringWithFormat:@"%d", LOCAL_PORT]];
            [arguments addObject:@"-k"];
            if (socksPass)
                [arguments addObject:socksPass];
            else
                [arguments addObject:@"123456"];
            if (useCrypto) {
                [arguments addObject:@"-m"];
                [arguments addObject:@"rc4"];
            }
            int argc = (int) [arguments count];
            const char *argv[argc + 1];
            argv[0] = "launcher";
            for (int i = 0; i < argc; i++)
                argv[i + 1] = [(NSString *) [arguments objectAtIndex:i] cStringUsingEncoding:NSUTF8StringEncoding];
            [NSThread detachNewThreadSelector:@selector(runPacServer) toTarget:[LauncherHelper class] withObject:nil];
            return local_main(argc + 1, argv);
        }
    }
    return 0;
}
