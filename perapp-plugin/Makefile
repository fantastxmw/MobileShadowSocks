include theos/makefiles/common.mk

TWEAK_NAME = SSPerApp
IPHONE_ARCHS = armv7 arm64
TARGET_IPHONEOS_DEPLOYMENT_VERSION = 5.0

SSPerApp_FILES = Tweak.x
SSPerApp_CFLAGS = -fvisibility=hidden
SSPerApp_LIBRARIES = substrate finder
SSPerApp_FRAMEWORKS = SystemConfiguration
SSPerApp_LDFLAGS = -Llibfinder

export PATH := $(shell pwd)/../extra:$(PATH)

include $(THEOS_MAKE_PATH)/tweak.mk

VERSION.INC_BUILD_NUMBER = 2

stage::
	find "$(THEOS_STAGING_DIR)" -type f \( -iname "*.strings" -o -iname "*.plist" \) -exec plutil -convert binary1 {} \;

package::
	mv -f $(THEOS_PACKAGE_NAME)*.deb ../release/
