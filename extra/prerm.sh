#!/bin/sh

if [[ $1 == remove || $1 == purge ]]; then
    /bin/launchctl unload /Library/LaunchDaemons/com.linusyang.shadowsocks.plist
fi

exit 0
