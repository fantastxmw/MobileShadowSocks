#!/bin/bash

set -e

if [[ "${XCODE_VERSION_MAJOR}" -ge "0460" ]]; then
    export TC_PATH="${DT_TOOLCHAIN_DIR}/usr/bin"
else
    export TC_PATH="${PLATFORM_DEVELOPER_BIN_DIR}"
fi

build_launcher() {
    SRCDIR="${PROJECT_DIR}/shadowsocks-libev"
    xcrun --sdk iphoneos clang \
        -arch "$1" \
        -miphoneos-version-min=6.0 \
        -O2 \
        -I"${SRCDIR}/libev" \
        -I"${PROJECT_DIR}/extra" \
        -I"${SRCDIR}/src" \
        -I"${BUILT_PRODUCTS_DIR}/ssl/include" \
        -DHAVE_CONFIG_H \
        -DUDPRELAY_LOCAL \
        -DVERSION="\"${NOWVER}-${NOWBUILD}\"" \
        -L"${BUILT_PRODUCTS_DIR}/ssl/lib" \
        -framework CoreFoundation \
        -framework SystemConfiguration \
        -lpolarssl \
        -o "$2" \
        "${SRCDIR}/src/encrypt.c" \
        "${SRCDIR}/src/local.c" \
        "${SRCDIR}/src/utils.c" \
        "${SRCDIR}/src/jconf.c" \
        "${SRCDIR}/src/json.c" \
        "${SRCDIR}/src/cache.c" \
        "${SRCDIR}/src/udprelay.c" \
        "${SRCDIR}/libev/ev.c"
    export CODESIGN_ALLOCATE="${TC_PATH}/codesign_allocate"
    "${PROJECT_DIR}/extra/ldid" -S "$2"
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
build_launcher arm64 shadowd64
build_launcher armv7 shadowd7
lipo -create -output shadowd shadowd64 shadowd7
mv -f shadowd makedeb/Applications/MobileShadowSocks.app/
mv -f backport/MobileShadowSocks-armv6 makedeb/Applications/MobileShadowSocks.app/ShadowSocks
mv -f backport/shadowd-armv6 makedeb/Applications/MobileShadowSocks.app/ShadowSocksDaemon
chmod 755 makedeb/Applications/MobileShadowSocks.app/shadowd
chmod 755 makedeb/Applications/MobileShadowSocks.app/MobileShadowSocks
chmod 755 makedeb/Applications/MobileShadowSocks.app/ShadowSocks
chmod 755 makedeb/Applications/MobileShadowSocks.app/ShadowSocksDaemon

# Clean temp files
rm -rf "${BUILT_PRODUCTS_DIR}/ssl/"
rm -rf "${BUILT_PRODUCTS_DIR}/backport/"
rm -f shadowd64 shadowd7

# Prepare app
/usr/libexec/PlistBuddy -c "Set :MinimumOSVersion 3.0" makedeb/Applications/MobileShadowSocks.app/Info.plist
/usr/bin/plutil -convert binary1 makedeb/Applications/MobileShadowSocks.app/Info.plist
rm -rf makedeb/Applications/MobileShadowSocks.app/CodeResources
rm -rf makedeb/Applications/MobileShadowSocks.app/_CodeSignature
mkdir -p makedeb/Library/LaunchDaemons
mv -f makedeb/Applications/MobileShadowSocks.app/com.linusyang.shadowsocks.plist makedeb/Library/LaunchDaemons/
/usr/bin/plutil -convert binary1 makedeb/Library/LaunchDaemons/com.linusyang.shadowsocks.plist
chmod 644 makedeb/Library/LaunchDaemons/com.linusyang.shadowsocks.plist

# Make package
find . -name .DS_Store -type f -delete
NOWSIZE="$(du -s -k makedeb | awk '{print $1}')"
CTRLFILE="Package: com.linusyang.shadowsocks\nSection: Networking\nInstalled-Size: $NOWSIZE\nAuthor: Linus Yang <laokongzi@gmail.com>\nArchitecture: iphoneos-arm\nVersion: $NOWVER-$NOWBUILD\nDescription: shadowsocks client for iOS\nName: ShadowSocks\nHomepage: https://github.com/linusyang/MobileShadowSocks\nIcon: file:///Applications/MobileShadowSocks.app/Icon.png\nTag: purpose::uikit\n"
DEBNAME="com.linusyang.shadowsocks_$NOWVER-$NOWBUILD"
mkdir -p makedeb/DEBIAN
echo -ne "${CTRLFILE}" > makedeb/DEBIAN/control
cp -f "${PROJECT_DIR}/extra/postinst.sh" makedeb/DEBIAN/postinst
cp -f "${PROJECT_DIR}/extra/prerm.sh" makedeb/DEBIAN/prerm
cp -f "${PROJECT_DIR}/extra/extrainst.sh" makedeb/DEBIAN/extrainst_
chmod 755 makedeb/DEBIAN/postinst
chmod 755 makedeb/DEBIAN/prerm
chmod 755 makedeb/DEBIAN/extrainst_
OLDPATH="${PATH}"
export PATH="${PROJECT_DIR}/extra:${PATH}"
"${PROJECT_DIR}/extra/fakeroot" "${PROJECT_DIR}/extra/dpkg-deb" -b makedeb t.deb
export PATH="${OLDPATH}"
mkdir -p "${PROJECT_DIR}/release"
mv -f t.deb "${PROJECT_DIR}/release/${DEBNAME}"_iphoneos-arm.deb

# Clean
rm -rf makedeb

# Build PerApp plugin
cd "${PROJECT_DIR}/perapp-plugin" && make package
