#!/bin/sh

if [[ $1 == remove || $1 == purge ]]; then
    /bin/launchctl unload -w /Library/LaunchDaemons/com.linusyang.shadowsocks.plist
    /Applications/MobileShadowSocks.app/shadowd -q
fi

exit 0
