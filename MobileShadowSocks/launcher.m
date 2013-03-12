//
//  launcher.m
//  MobileShadowSocks Launcher
//
//  Created by Linus Yang on 13-3-4.
//  Copyright (c) 2013 Linus Yang. All rights reserved.
//

#import "LauncherHelper.h"
#import "build_time.h"
#import <arpa/inet.h>

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
        
        NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:PREF_FILE];
        if (dict && [[NSFileManager defaultManager] isExecutableFileAtPath:SHADOW_BIN]) {
            NSString *remoteServer = (NSString *) [dict objectForKey:@"REMOTE_SERVER"];
            NSString *remotePort = (NSString *) [dict objectForKey:@"REMOTE_PORT"];
            NSString *socksPass = (NSString *) [dict objectForKey:@"SOCKS_PASS"];
            BOOL useCrypto = [[dict objectForKey:@"USE_RC4"] boolValue];
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
            const char *executable = [SHADOW_BIN cStringUsingEncoding:NSUTF8StringEncoding];
            int ac = (int) [arguments count];
            const char *args[ac + 2];
            int i;
            pid_t pid;
            args[0] = [[SHADOW_BIN lastPathComponent] cStringUsingEncoding:NSUTF8StringEncoding];
            for (i = 0; i < ac; i++) {
                NSString *arg = (NSString *) [arguments objectAtIndex:i];
                args[i + 1] = [arg cStringUsingEncoding:NSUTF8StringEncoding];
            }
            args[ac + 1] = 0;
            pid = fork();
            if (pid == 0) {
                execv(executable, (char **) args);
                exit(0);
            }
        }
        
        struct sockaddr_in client;
        struct sockaddr_in server;
        socklen_t socksize = sizeof(struct sockaddr_in);
        int sock;
        int conn;
        int optval = 1;
        FILE *stream;
        BOOL autoProxy;
        NSString *pacFile;
        
        memset(&server, 0, sizeof(server));
        server.sin_family = AF_INET;
        server.sin_addr.s_addr = inet_addr("127.0.0.1");
        server.sin_port = htons(PAC_PORT);
        sock = socket(AF_INET, SOCK_STREAM, 0);
        if (sock < 0) {
            fprintf(stderr, "Error: cannot open socket\n");
            exit(1);
        }
        setsockopt(sock, SOL_SOCKET, SO_REUSEADDR, (const void *)&optval , sizeof(int));
        if (bind(sock, (struct sockaddr *) &server, sizeof(struct sockaddr)) < 0) {
            fprintf(stderr, "Error: cannot bind port\n");
            close(sock);
            exit(1);
        }
        if (listen(sock, 10) < 0) {
            fprintf(stderr, "Error: cannot listen on port\n");
            close(sock);
            exit(1);
        }
        while (1) {
            conn = accept(sock, (struct sockaddr *) &client, &socksize);
            if (conn < 0) {
                fprintf(stderr, "Error: cannot accept\n");
                close(sock);
                exit(1);
            }
            if (!(stream = fdopen(conn, "r+"))) {
                fprintf(stderr, "Error: cannot open stream\n");
                close(sock);
                exit(1);
            }
            fprintf(stream, HTTP_RESPONSE);
            BOOL sent = NO;
            dict = [NSDictionary dictionaryWithContentsOfFile:PREF_FILE];
            if (dict) {
                autoProxy = [[dict objectForKey:@"AUTO_PROXY"] boolValue];
                if (autoProxy) {
                    pacFile = (NSString *) [dict objectForKey:@"PAC_FILE"];
                    NSString *filePath = DEFAULT_PAC;
                    if (pacFile) {
                        pacFile = [pacFile stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                        if ([[NSFileManager defaultManager] fileExistsAtPath:pacFile])
                            filePath = pacFile;
                    }
                    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
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
    }
    return 0;
}
