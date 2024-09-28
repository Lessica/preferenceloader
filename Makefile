# DON'T USE THIS MAKEFILE! IT IS NOT INTENDED FOR UPSTREAM THEOS

ifeq ($(SIMULATOR),1)
TARGET := simulator:clang:latest:14.0
ARCHS = arm64
else
TARGET := iphone:clang:14.5:14.0
ARCHS = arm64e
endif

export THEOS_USE_NEW_ABI=1

include $(THEOS)/makefiles/common.mk

ifeq ($(ROOTLESS),1)
export INSTALL_PREFIX = /var/jb
else
export INSTALL_PREFIX = 
endif

LIBRARY_NAME += libprefs
libprefs_FILES += prefs.xm
libprefs_FRAMEWORKS += UIKit
libprefs_FRAMEWORKS += CydiaSubstrate
libprefs_PRIVATE_FRAMEWORKS += Preferences
libprefs_CFLAGS += -I.

ifeq ($(SIMULATOR),1)
libprefs_CFLAGS += -DSIMULATOR=1
libprefs_CFLAGS += -DROOTLESS=1
else
libprefs_CFLAGS += -DROOTLESS=0
endif

ifeq ($(SIMULATOR),1)
libprefs_LDFLAGS += -FLibrary/_Simulator
libprefs_LDFLAGS += -rpath /opt/simject
libprefs_INSTALL_PATH := @rpath
else
libprefs_COMPATIBILITY_VERSION = 2.2.0
libprefs_LIBRARY_VERSION = $(shell echo "$(THEOS_PACKAGE_BASE_VERSION)" | cut -d'~' -f1)
libprefs_LDFLAGS += -compatibility_version $($(THEOS_CURRENT_INSTANCE)_COMPATIBILITY_VERSION)
libprefs_LDFLAGS += -current_version $($(THEOS_CURRENT_INSTANCE)_LIBRARY_VERSION)
libprefs_LDFLAGS += -rpath /var/jb/usr/lib -rpath /usr/lib
libprefs_INSTALL_PATH := $(INSTALL_PREFIX)/usr/lib
endif

TWEAK_NAME += PreferenceLoader
PreferenceLoader_FILES += Tweak.xm
PreferenceLoader_FRAMEWORKS += UIKit
PreferenceLoader_PRIVATE_FRAMEWORKS += Preferences
PreferenceLoader_LIBRARIES += prefs
PreferenceLoader_CFLAGS += -I.

ifeq ($(SIMULATOR),1)
PreferenceLoader_CFLAGS += -DSIMULATOR=1
PreferenceLoader_CFLAGS += -DROOTLESS=1
else
PreferenceLoader_CFLAGS += -DROOTLESS=0
endif

PreferenceLoader_LDFLAGS += -L$(THEOS_OBJ_DIR)

ifeq ($(SIMULATOR),1)
PreferenceLoader_LDFLAGS += -FLibrary/_Simulator
PreferenceLoader_LDFLAGS += -rpath /opt/simject
else
PreferenceLoader_LDFLAGS += -rpath /var/jb/usr/lib -rpath /usr/lib
endif

ifeq ($(SIMULATOR),1)
PreferenceLoader_INSTALL_PATH := @rpath
else
ifeq ($(ROOTLESS),1)
PreferenceLoader_INSTALL_PATH := $(INSTALL_PREFIX)/usr/lib/TweakInject
else
PreferenceLoader_INSTALL_PATH := $(INSTALL_PREFIX)/Library/MobileSubstrate/DynamicLibraries
endif
endif

include $(THEOS_MAKE_PATH)/library.mk
include $(THEOS_MAKE_PATH)/tweak.mk

export THEOS_OBJ_DIR
after-all::
	@devkit/sim-install.sh

after-libprefs-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/$(INSTALL_PREFIX)/usr/include/libprefs$(ECHO_END)
	$(ECHO_NOTHING)cp prefs.h $(THEOS_STAGING_DIR)/$(INSTALL_PREFIX)/usr/include/libprefs/prefs.h$(ECHO_END)

after-stage::
	@find $(THEOS_STAGING_DIR) -iname '*.plist' -exec plutil -convert binary1 {} \;
#   $(FAKEROOT) chown -R root:admin $(THEOS_STAGING_DIR)
	@mkdir -p $(THEOS_STAGING_DIR)/$(INSTALL_PREFIX)/Library/PreferenceBundles $(THEOS_STAGING_DIR)/$(INSTALL_PREFIX)/Library/PreferenceLoader/Preferences
# 	sudo chown -R root:admin $(THEOS_STAGING_DIR)/Library $(THEOS_STAGING_DIR)/usr

after-install::
	install.exec "killall -9 Preferences"
