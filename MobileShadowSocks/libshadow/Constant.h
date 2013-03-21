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
#define APP_BUILD @"1"

#define CELL_TEXT @"TextField"
#define CELL_PASS @"Pass"
#define CELL_NUM @"Num"
#define CELL_SWITCH @"Switch"
#define CELL_NOTIFY @"Notify"
#ifdef TARGET_OS_MAC
#define PREF_FILE @"/Users/linusyang/Downloads/Keep/whitelist/com.linusyang.MobileShadowSocks.plist"
#else
#define PREF_FILE @"/var/mobile/Library/Preferences/com.linusyang.MobileShadowSocks.plist"
#endif

#define STORE_ID CFSTR("shadow")
#define SC_IDENTI CFSTR("State:/Network/Service/[^/]+/IPv[46]")

#define LOCAL_PORT 1983
#define PAC_PORT 1993
#define BUFF_SIZE 1024
#define REMOTE_TIMEOUT 10
#define LOCAL_TIMEOUT 60
#define EMPTY_PAC "function FindProxyForURL(url, host) \n{\n  return 'SOCKS 127.0.0.1:%d';\n}\n"
#define HTTP_RESPONSE "HTTP/1.1 200 OK\r\nServer: Pac HTTP Server\r\nContent-Type: text/plain\r\n\r\n"
#define UPDATE_CONF "Update-Conf"
#define LAUNCHD_NAME_SOCKS "SOCKS"
#define LAUNCHD_NAME_PAC "PAC"

#endif
