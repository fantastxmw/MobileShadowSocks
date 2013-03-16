//
//  Constant.h
//  MobileShadowSocks
//
//  Created by Linus Yang on 13-3-5.
//  Copyright (c) 2013 Linus Yang. All rights reserved.
//

#ifndef MobileShadowSocks_Constant_h
#define MobileShadowSocks_Constant_h

#define APP_VER @"0.2.2"
#define APP_BUILD @"6"

#define CELL_TEXT @"TextField"
#define CELL_PASS @"Pass"
#define CELL_NUM @"Num"
#define CELL_SWITCH @"Switch"
#define CELL_ALWAYS @"Always"

#define DAEMON_ID @"com.linusyang.shadowsocks"
#define BUNDLE_PATH @"/Applications/MobileShadowSocks.app"
#define PREF_FILE @"/var/mobile/Library/Preferences/com.linusyang.MobileShadowSocks.plist"

#define STORE_ID CFSTR("shadow")
#define SC_IDENTI CFSTR("State:/Network/Service/[^/]+/IPv[46]")

#define LOCAL_PORT 1983
#define PAC_PORT 1993
#define BUFF_SIZE 1024
#define EMPTY_PAC "function FindProxyForURL(url, host) \n{\n  return 'SOCKS 127.0.0.1:%d';\n}\n"
#define HTTP_RESPONSE "HTTP/1.1 200 OK\r\nServer: Pac HTTP Server\r\nContent-Type: text/plain\r\n\r\n"
#define USAGE_STR "shadowsocks launcher (build %s)\nUsage: %s [options]\n\nOptions:\n-r\tRun shadowsocks daemon\n-s\tStop shadowsocks daemon\n-p\tEnable proxy settings\n-n\tDisable proxy settings\n-k\tEnable socks proxy settings\n"

#endif
