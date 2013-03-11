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
#define APP_BUILD @"4"

#define CELL_TEXT @"TextField"
#define CELL_PASS @"Pass"
#define CELL_NUM @"Num"
#define CELL_SWITCH @"Switch"
#define CELL_ALWAYS @"Always"

#define DAEMON_ID @"com.linusyang.shadowsocks"
#define BUNDLE_PATH @"/Applications/MobileShadowSocks.app"
#define SHADOW_BIN BUNDLE_PATH @"/shadow"
#define DEFAULT_PAC BUNDLE_PATH @"/auto.pac"
#define PREF_FILE @"/var/mobile/Library/Preferences/com.linusyang.MobileShadowSocks.plist"
#define SC_STORE @"/var/preferences/SystemConfiguration/preferences.plist"
#define SC_IDENTI @"show com.apple.network.identification\nlist State:/Network/Service/[^/]+/com.apple.CommCenter\nlist State:/Network/Service/[^/]+/DHCP\nlist State:/Network/Service/[^/]+/IPv[46]\n"

#define LOCAL_PORT 1983
#define PAC_PORT 1993
#define EMPTY_PAC "function FindProxyForURL(url, host) \n{\n  return 'SOCKS 127.0.0.1:%d';\n}\n"
#define HTTP_RESPONSE "HTTP/1.1 200 OK\nServer: Pac HTTP Server\nContent-Type: text/plain\n\n"
#define USAGE_STR "Usage: %s [options]\n\nOptions:\n-r\tRun shadowsocks daemon\n-s\tStop shadowsocks daemon\n-p\tEnable proxy settings\n-n\tDisable proxy settings\n"

#define LAUNCH_CTL_PATH "/bin/launchctl"
#define SC_UTIL_PATH "/usr/sbin/scutil"

#endif
