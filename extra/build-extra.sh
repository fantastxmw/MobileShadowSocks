#!/bin/bash

set -e

if [[ "${XCODE_VERSION_MAJOR}" -ge "0460" ]]; then
    export TC_PATH="${DT_TOOLCHAIN_DIR}/usr/bin"
else
    export TC_PATH="${PLATFORM_DEVELOPER_BIN_DIR}"
fi

build_launcher() {
    export CODESIGN_ALLOCATE="${TC_PATH}/codesign_allocate"
    SRCDIR="${PROJECT_DIR}/shadowsocks-libev"
    "${TC_PATH}/clang" -arch "$1" -O3 -I"${SRCDIR}/libev" -I"${PROJECT_DIR}/extra" -I"${SRCDIR}/src" -I"${SDKROOT}/usr/include" -I"${BUILT_PRODUCTS_DIR}/ssl/include" -DHAVE_CONFIG_H -DUDPRELAY_LOCAL -DVERSION="\"${NOWVER}-${NOWBUILD}\"" -L"${SDKROOT}/usr/lib" -L"${BUILT_PRODUCTS_DIR}/ssl/lib" -miphoneos-version-min=7.0 -isysroot "${SDKROOT}" -framework CoreFoundation -framework SystemConfiguration -lcrypto "${SRCDIR}/src/encrypt.c" "${SRCDIR}/src/local.c" "${SRCDIR}/src/utils.c" "${SRCDIR}/src/jconf.c" "${SRCDIR}/src/json.c" "${SRCDIR}/src/cache.c" "${SRCDIR}/src/udprelay.c" "${SRCDIR}/libev/ev.c" -o "$2"
    "${PROJECT_DIR}/extra/ldid" -S "$2"
}

try_build_legacy() {
    export LEGACY_TC="/usr/local/iphonesdk/toolchain-5.1/usr/bin"
    export LEGACY_SDK="/usr/local/iphonesdk/iPhoneOS5.1.sdk"
    if [ -d "${LEGACY_TC}" ] && [ -d "${LEGACY_SDK}" ]; then
        export LEGACY_DAEMON="${BUILT_PRODUCTS_DIR}/backport/shadowd-armv6"
        export LEGACY_GUI="${BUILT_PRODUCTS_DIR}/backport/MobileShadowSocks-armv6"
        export CODESIGN_ALLOCATE="${LEGACY_TC}/codesign_allocate"
        SRCDIR="${PROJECT_DIR}/shadowsocks-libev"
        GUIDIR="${PROJECT_DIR}/MobileShadowSocks"
        rm -f "${LEGACY_DAEMON}" "${LEGACY_GUI}"
        "${LEGACY_TC}/clang" -arch armv6 -Os -I"${SRCDIR}/libev" -I"${PROJECT_DIR}/extra" -I"${SRCDIR}/src" -I"${LEGACY_SDK}/usr/include" -I"${BUILT_PRODUCTS_DIR}/ssl/include" -DHAVE_CONFIG_H -DUDPRELAY_LOCAL -DVERSION="\"${NOWVER}-${NOWBUILD}\"" -L"${LEGACY_SDK}/usr/lib" -L"${BUILT_PRODUCTS_DIR}/ssl/lib" -miphoneos-version-min=3.0 -isysroot "${LEGACY_SDK}" -framework CoreFoundation -framework SystemConfiguration -lcrypto "${SRCDIR}/src/encrypt.c" "${SRCDIR}/src/local.c" "${SRCDIR}/src/utils.c" "${SRCDIR}/src/jconf.c" "${SRCDIR}/src/json.c" "${SRCDIR}/src/cache.c" "${SRCDIR}/src/udprelay.c" "${SRCDIR}/libev/ev.c" -o "${LEGACY_DAEMON}"
        "${PROJECT_DIR}/extra/ldid" -S "${LEGACY_DAEMON}"
        "${LEGACY_TC}/clang" -arch armv6 -x objective-c -Os -I"${GUIDIR}" -I"${LEGACY_SDK}/usr/include" -L"${LEGACY_SDK}/usr/lib" -miphoneos-version-min=3.0 -isysroot "${LEGACY_SDK}" -framework Foundation -framework CFNetwork -framework UIKit -framework Foundation -framework CoreGraphics -framework CoreFoundation "${GUIDIR}/AppDelegate.m" "${GUIDIR}/CipherViewController.m" "${GUIDIR}/ProfileViewController.m" "${GUIDIR}/SettingTableViewController.m" "${GUIDIR}/main.m" -o "${LEGACY_GUI}"
        "${PROJECT_DIR}/extra/ldid" -S "${LEGACY_GUI}"
    fi
}

# Codesign
export CODESIGN_ALLOCATE="${TC_PATH}/codesign_allocate"
python "${PROJECT_DIR}/extra/gen_entitlements.py" "com.linusyang.${PRODUCT_NAME}" "${BUILT_PRODUCTS_DIR}/${WRAPPER_NAME}/${PROJECT_NAME}.xcent";
codesign -f -s "iPhone Developer" --entitlements "${BUILT_PRODUCTS_DIR}/${WRAPPER_NAME}/${PROJECT_NAME}.xcent" "${BUILT_PRODUCTS_DIR}/${WRAPPER_NAME}/"
rm -f "${BUILT_PRODUCTS_DIR}/${WRAPPER_NAME}/${PROJECT_NAME}.xcent"

# Version info
VERINFO="${PROJECT_DIR}/MobileShadowSocks/SettingTableViewController.m"
NOWVER="$(grep "APP_VER" "${VERINFO}" | awk '{print $3}' | sed 's/["@]//g' | head -1)"
NOWBUILD="$(grep "APP_BUILD" "${VERINFO}" | awk '{print $3}' | sed 's/["@]//g' | head -1)"

# Clean old build
cd "${BUILT_PRODUCTS_DIR}"
rm -rf makedeb
rm -f *.deb
mkdir -p makedeb

# Fix permission
chmod 755 "${PROJECT_DIR}/extra/ldid"
chmod 755 "${PROJECT_DIR}/extra/dpkg-deb"
chmod 755 "${PROJECT_DIR}/extra/gnutar"

# Copy app
mkdir -p makedeb/Applications
cp -r "${WRAPPER_NAME}" makedeb/Applications/

# Clean and extract build
rm -rf "${BUILT_PRODUCTS_DIR}/ssl/"
rm -rf "${BUILT_PRODUCTS_DIR}/backport/"
rm -f shadowd7 MobileShadowSocks7
tar zxf "${PROJECT_DIR}/extra/ssl.tgz" -C "${BUILT_PRODUCTS_DIR}/"
tar zxf "${PROJECT_DIR}/extra/backport.tgz" -C "${BUILT_PRODUCTS_DIR}/"

# Build and bundle binary
try_build_legacy
build_launcher arm64 shadowd64
build_launcher armv7 shadowd7
mv -f makedeb/Applications/MobileShadowSocks.app/MobileShadowSocks MobileShadowSocks7
lipo -create -output shadowd shadowd64 shadowd7 backport/shadowd-armv6
lipo -create -output MobileShadowSocks MobileShadowSocks7 backport/MobileShadowSocks-armv6
mv -f shadowd makedeb/Applications/MobileShadowSocks.app/
mv -f MobileShadowSocks makedeb/Applications/MobileShadowSocks.app/
chmod 755 makedeb/Applications/MobileShadowSocks.app/shadowd
chmod 755 makedeb/Applications/MobileShadowSocks.app/MobileShadowSocks

# Clean temp files
rm -rf "${BUILT_PRODUCTS_DIR}/ssl/"
rm -rf "${BUILT_PRODUCTS_DIR}/backport/"
rm -f shadowd64 shadowd7 MobileShadowSocks7

# Prepare app
/usr/libexec/PlistBuddy -c "Set :MinimumOSVersion 3.0" makedeb/Applications/MobileShadowSocks.app/Info.plist
/usr/bin/plutil -convert binary1 makedeb/Applications/MobileShadowSocks.app/Info.plist
rm -rf makedeb/Applications/MobileShadowSocks.app/CodeResources
ln -s _CodeSignature/CodeResources makedeb/Applications/MobileShadowSocks.app/CodeResources
mkdir -p makedeb/Library/LaunchDaemons
mv -f makedeb/Applications/MobileShadowSocks.app/com.linusyang.shadowsocks.plist makedeb/Library/LaunchDaemons/
/usr/bin/plutil -convert binary1 makedeb/Library/LaunchDaemons/com.linusyang.shadowsocks.plist
chmod 644 makedeb/Library/LaunchDaemons/com.linusyang.shadowsocks.plist

# Make package
find . -name .DS_Store -type f -delete
NOWSIZE="$(du -s -k makedeb | awk '{print $1}')"
CTRLFILE="Package: com.linusyang.shadowsocks\nSection: Networking\nInstalled-Size: $NOWSIZE\nAuthor: Linus Yang <laokongzi@gmail.com>\nArchitecture: iphoneos-arm\nVersion: $NOWVER-$NOWBUILD\nDescription: shadowsocks client for iOS\nName: ShadowSocks\nHomepage: https://github.com/linusyang/MobileShadowSocks\nIcon: file:///Applications/MobileShadowSocks.app/Icon.png\nTag: purpose::uikit\n"
POSTFILE='#!/bin/sh\nBUNDLE="/Applications/MobileShadowSocks.app"\nchmod 755 "${BUNDLE}/MobileShadowSocks"\nchmod 755 "${BUNDLE}/shadowd"\nchown -R 0:0 "${BUNDLE}"\nexit 0\n'
EXTRA='#!/bin/sh\n\nchmod 644 /Library/LaunchDaemons/com.linusyang.shadowsocks.plist\nchown 0:0 /Library/LaunchDaemons/com.linusyang.shadowsocks.plist\n\nif [[ $1 == upgrade ]]; then\n    /bin/launchctl unload -w /Library/LaunchDaemons/com.linusyang.shadowsocks.plist\nfi\n\nif [[ $1 == install || $1 == upgrade ]]; then\n    /bin/launchctl load -w /Library/LaunchDaemons/com.linusyang.shadowsocks.plist\nfi\n\nexit 0\n'
PRERM='#!/bin/sh\n\nif [[ $1 == remove || $1 == purge ]]; then\n    /bin/launchctl unload -w /Library/LaunchDaemons/com.linusyang.shadowsocks.plist\nfi\n\nexit 0\n'
DEBNAME="com.linusyang.shadowsocks_$NOWVER-$NOWBUILD"
mkdir -p makedeb/DEBIAN
echo -ne "${CTRLFILE}" > makedeb/DEBIAN/control
echo -ne "${POSTFILE}" > makedeb/DEBIAN/postinst
echo -ne "${PRERM}" > makedeb/DEBIAN/prerm
echo -ne "${EXTRA}" > makedeb/DEBIAN/extrainst_
chmod 755 makedeb/DEBIAN/postinst
chmod 755 makedeb/DEBIAN/prerm
chmod 755 makedeb/DEBIAN/extrainst_
OLDPATH="${PATH}"
export PATH="${PROJECT_DIR}/extra:${PATH}"
"${PROJECT_DIR}/extra/dpkg-deb" -b makedeb t.deb
export PATH="${OLDPATH}"
mkdir -p "${PROJECT_DIR}/release"
mv -f t.deb "${PROJECT_DIR}/release/${DEBNAME}"_iphoneos-arm.deb

# Clean
rm -rf makedeb
