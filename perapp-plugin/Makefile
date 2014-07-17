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

VERSION.INC_BUILD_NUMBER = 1

stage::
	plutil -convert binary1 "$(THEOS_STAGING_DIR)/Library/MobileSubstrate/DynamicLibraries/$(TWEAK_NAME).plist"
	plutil -convert binary1 "$(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/com.linusyang.ssperapp/entry.plist"
	plutil -convert binary1 "$(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/com.linusyang.ssperapp/zh-Hans.lproj/Localizable.strings"
	plutil -convert binary1 "$(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/com.linusyang.ssperapp/zh-Hant.lproj/Localizable.strings"

package::
	mv -f $(THEOS_PACKAGE_NAME)*.deb ../release/
