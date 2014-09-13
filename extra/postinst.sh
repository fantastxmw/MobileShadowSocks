#!/bin/sh

# File paths
BUNDLE="/Applications/MobileShadowSocks.app"
MAINBIN="${BUNDLE}/MobileShadowSocks"
DAEMON="${BUNDLE}/shadowd"

# Check if files exist
if  [ ! -d "${BUNDLE}" ] || [ ! -f "${MAINBIN}" ] || [ ! -f "${DAEMON}" ]; then
    echo "Error: file is missing. Please reinstall the package."
    exit 1
fi

# Check system version
if [ -x /usr/bin/sw_vers ]; then
    SYS_VER="$(/usr/bin/sw_vers -productVersion)"
    if [ ! -z "${SYS_VER}" ]; then
        MAIN_VER="${SYS_VER%%.*}"
        LEGACYBIN="${BUNDLE}/ShadowSocks"
        LEGACYDAEMON="${BUNDLE}/ShadowSocksDaemon"
        if [[ "${MAIN_VER}" -lt 6 ]]; then
            if [ -f "${LEGACYBIN}" ]; then
                mv -f "${MAINBIN}" "${LEGACYBIN}_"
                mv -f "${LEGACYBIN}" "${MAINBIN}"
                mv -f "${LEGACYBIN}_" "${LEGACYBIN}"
            fi
            if [ -f "${LEGACYDAEMON}" ]; then
                mv -f "${DAEMON}" "${LEGACYDAEMON}_"
                mv -f "${LEGACYDAEMON}" "${DAEMON}"
                mv -f "${LEGACYDAEMON}_" "${LEGACYDAEMON}"
            fi
        fi
    fi
fi

# Set permissions
chmod 755 "${MAINBIN}" "${DAEMON}"
chown -R 0:0 "${BUNDLE}"

exit 0
