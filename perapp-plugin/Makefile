include theos/makefiles/common.mk

TWEAK_NAME = SSPerApp
IPHONE_ARCHS = armv7 arm64
TARGET_IPHONEOS_DEPLOYMENT_VERSION = 5.0

SSPerApp_FILES = Tweak.x
SSPerApp_CFLAGS = -fvisibility=hidden
SSPerApp_LIBRARIES = substrate
SSPerApp_FRAMEWORKS = SystemConfiguration

include $(THEOS_MAKE_PATH)/tweak.mk

stage::
	plutil -convert binary1 "$(THEOS_STAGING_DIR)/Library/MobileSubstrate/DynamicLibraries/$(TWEAK_NAME).plist"
	plutil -convert binary1 "$(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/com.linusyang.ssperapp/entry.plist"
	plutil -convert binary1 "$(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/com.linusyang.ssperapp/zh-Hans.lproj/Localizable.strings"
	plutil -convert binary1 "$(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/com.linusyang.ssperapp/zh-Hant.lproj/Localizable.strings"
