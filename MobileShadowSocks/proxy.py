#!/usr/bin/env python
# -*- coding: utf-8 -*-
#
# ShadowSocks Launcher for iOS
# By Linus Yang <laokongzi@gmail.com>
#
# Shadowsocks is a project created by @clowwindy:
#   https://github.com/clowwindy/shadowsocks
#
# Based on script *change_sysproxy.py* by @hewigovens
# Distributed under WTFPL v2 License:
#
#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#                   Version 2, December 2004
#
# Copyright (C) 2004 Sam Hocevar <sam@hocevar.net>
#
# Everyone is permitted to copy and distribute verbatim or modified
# copies of this license document, and changing it is allowed as long
# as the name is changed.
#
#           DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#  TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
#
# 0. You just DO WHAT THE FUCK YOU WANT TO.
#

import os
import re
from subprocess import Popen, PIPE, STDOUT, call
from optparse import OptionParser
from BaseHTTPServer import HTTPServer, BaseHTTPRequestHandler

# Warning: DO NOT change values below
PAC_SERVER_PORT   = 1993
NETWORK_KEY       = 'NetworkServices'
PROXY_KEY         = 'Proxies'
PAC_ENABLE_KEY    = 'ProxyAutoConfigEnable'
PAC_STRING_KEY    = 'ProxyAutoConfigURLString'
PAC_STRING_VALUE  = 'http://127.0.0.1:%d/shadow.pac' % PAC_SERVER_PORT
HTTP_ENABLE_KEY   = 'HTTPEnable'
HTTPS_ENABLE_KEY  = 'HTTPSEnable'
HTTP_PORT_KEY     = 'HTTPPort'
HTTP_PORT_VALUE   = 1983
HTTP_PROXY_KEY    = 'HTTPProxy'
HTTP_PROXY_VALUE  = '127.0.0.1' 
HTTPS_PORT_KEY    = 'HTTPSPort'
HTTPS_PORT_VALUE  = 1983
HTTPS_PROXY_KEY   = 'HTTPSProxy'
HTTPS_PROXY_VALUE = '127.0.0.1' 
PROXY_TYPE_KEY    = 'HTTPProxyType'
FTP_PASSIVE_KEY   = 'FTPPassive'
EXCEPTION_KEY     = 'ExceptionsList'
EXCEPTION_VALUE   = ['localhost', '127.0.0.1', '*.local']
SCUTIL_BINARY     = 'scutil'
LOCAL_BINARY      = '/Applications/MobileShadowSocks.app/shadow'
LOCAL_PORT        = '1983'
PAC_FILE          = '/Applications/MobileShadowSocks.app/empty.pac'
AUTO_PAC_FILE     = '/Applications/MobileShadowSocks.app/auto.pac'
EMPTY_PAC_FILE    = '/Applications/MobileShadowSocks.app/empty.pac'
CONF_FILE         = '/Applications/MobileShadowSocks.app/proxy.conf'

class PacHTTPHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        try:
            if self.path == '/shadow.pac':
                f = open(PAC_FILE, 'rb')
                self.send_response(200)
                self.send_header("Content-type", "text/plain")
                self.end_headers()
                self.wfile.write(f.read())
                f.close()
            else:
                self.send_error(404, 'File not found')
        except IOError:
            self.send_error(404, 'File not found')

def get_sc(key, value, overwrite=False, split=''):
    if overwrite:
        return 'd.add %s %s%s\n' % (key, split, str(value))
    else:
        return ''

def get_udid(cmd):
    scid_string = Popen([SCUTIL_BINARY], stdin=PIPE, stdout=PIPE).communicate(input=cmd)[0]
    return re.findall(r'[A-F0-9]{8}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{12}', scid_string)

def main():
    parser = OptionParser()
    parser.add_option("-t", "--http", action="store_true", dest="http", default=False, \
                      help="Enable HTTP & HTTPS proxy.")
    parser.add_option("-p", "--pac", action="store_true", dest="pac", default=False, \
                      help="Enable PAC proxy.")
    (options, args) = parser.parse_args()
    http_enabled = 0
    pac_enabled = 0
    proxy_type = 0
    except_list = EXCEPTION_VALUE
    if options.http:
        http_enabled = 1
        proxy_type = 1
    elif options.pac:
        pac_enabled = 1
        proxy_type = 2
    confs = {}
    if os.path.isfile(CONF_FILE):
        execfile(CONF_FILE, confs)
    if confs.get('EXCEPTION_LIST') != None:
        except_list += confs.get('EXCEPTION_LIST')
    if confs.get('AUTO_PROXY'):
        global PAC_FILE
        PAC_FILE = AUTO_PAC_FILE
    identifiers = []
    try:
        identifiers += get_udid('show com.apple.network.identification')
        identifiers += get_udid('list State:/Network/Service/[^/]+/com.apple.CommCenter')
        identifiers += get_udid('list State:/Network/Service/[^/]+/DHCP')
        identifiers = list(set(identifiers))
    except:
        return
    for interface in identifiers:
        p = "d.init\n"
        p += get_sc(EXCEPTION_KEY, ' '.join(except_list), options.pac or options.http, '* ')
        p += get_sc(HTTP_ENABLE_KEY, http_enabled, True, '# ')
        p += get_sc(HTTP_PORT_KEY, HTTP_PORT_VALUE, options.http, '# ')
        p += get_sc(HTTP_PROXY_KEY, HTTP_PROXY_VALUE, options.http)
        p += get_sc(PROXY_TYPE_KEY, proxy_type, True, '# ')
        p += get_sc(HTTPS_ENABLE_KEY, http_enabled, True, '# ')
        p += get_sc(HTTPS_PORT_KEY, HTTPS_PORT_VALUE, options.http, '# ')
        p += get_sc(HTTPS_PROXY_KEY, HTTPS_PROXY_VALUE, options.http)
        p += get_sc(PAC_ENABLE_KEY, pac_enabled, True, '# ')
        p += get_sc(PAC_STRING_KEY, PAC_STRING_VALUE, options.pac)
        p += 'set Setup:/Network/Service/%s/Proxies\n' % interface
        try:
            Popen([SCUTIL_BINARY], stdin=PIPE).communicate(input=p)[0]
        except:
            pass
    if options.pac:
        proxy_run_args = [LOCAL_BINARY, '-s', confs.get('REMOTE_SERVER'), '-p', confs.get('REMOTE_PORT'), '-l', LOCAL_PORT, '-k', confs.get('SOCKS_PASS')]
        if confs.get('USE_RC4'):
            proxy_run_args += ['-m', 'rc4']
        Popen(proxy_run_args)
        try:
            server = HTTPServer(('127.0.0.1', PAC_SERVER_PORT), PacHTTPHandler)
            server.serve_forever()
        except:
            pass

if __name__ == '__main__':
    main()
