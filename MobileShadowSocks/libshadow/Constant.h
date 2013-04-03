//
//  Constant.h
//  MobileShadowSocks
//
//  Created by Linus Yang on 13-3-5.
//  Copyright (c) 2013 Linus Yang. All rights reserved.
//

#ifndef MobileShadowSocks_Constant_h
#define MobileShadowSocks_Constant_h

#define APP_VER @"0.2.3"
#define APP_BUILD @"3"

#define CELL_TEXT @"TextField"
#define CELL_PASS @"Pass"
#define CELL_NUM @"Num"
#define CELL_SWITCH @"Switch"
#define CELL_NOTIFY @"Notify"
#define CELL_BUTTON @"Button"
#define ALERT_TAG_ABOUT 1
#define ALERT_TAG_DEFAULT_PAC 2
#ifdef BUILD_FOR_MAC
#define PREF_FILE @"/Users/linusyang/Downloads/Keep/whitelist/com.linusyang.MobileShadowSocks.plist"
#else
#define PREF_FILE @"/var/mobile/Library/Preferences/com.linusyang.MobileShadowSocks.plist"
#endif

#define LOCAL_PORT 1983
#define PAC_PORT 1993
#define BUFF_MAX 1024
#define REMOTE_TIMEOUT 10
#define LOCAL_TIMEOUT 60
#define EMPTY_PAC_HEAD "function FindProxyForURL(url, host) {\n"
#ifdef BUILD_FOR_MAC
#define EMPTY_PAC_TAIL "    if (host == '127.0.0.1' || host == 'localhost')\n        return 'DIRECT'\n    return 'SOCKS5 127.0.0.1:%d';\n}\n"
#else
#define EMPTY_PAC_TAIL "    if (host == '127.0.0.1' || host == 'localhost')\n        return 'DIRECT'\n    return 'SOCKS 127.0.0.1:%d';\n}\n"
#endif
#define HTTP_RESPONSE "HTTP/1.1 200 OK\r\nServer: Pac HTTP Server\r\nContent-Type: application/x-ns-proxy-autoconfig\r\nConnection: close\r\n\r\n"
#define UPDATE_CONF "Update-Conf"
#define LAUNCHD_NAME_SOCKS "SOCKS"
#define LAUNCHD_NAME_PAC "PAC"
#define PAC_FUNC "FindProxyForURL"
#define PAC_EXCEPT_HEAD "\n    var lhost = host.toLowerCase();\n"
#define PAC_EXCEPT_ENTRY @"    if (shExpMatch(lhost, '%@')) return 'DIRECT';\n    if (shExpMatch(lhost, '*.%@')) return 'DIRECT';\n"

#endif
