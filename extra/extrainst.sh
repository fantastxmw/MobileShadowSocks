#!/bin/sh

chmod 644 /Library/LaunchDaemons/com.linusyang.shadowsocks.plist
chown 0:0 /Library/LaunchDaemons/com.linusyang.shadowsocks.plist

if [[ $1 == upgrade ]]; then
    /bin/launchctl unload -w /Library/LaunchDaemons/com.linusyang.shadowsocks.plist
fi

if [[ $1 == install || $1 == upgrade ]]; then
    /bin/launchctl load -w /Library/LaunchDaemons/com.linusyang.shadowsocks.plist
fi

exit 0
