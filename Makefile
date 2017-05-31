include theos/makefiles/common.mk

TWEAK_NAME = trustAlert
trustAlert_FILES = /mnt/d/codes/trustalert/Tweak.xm
trustAlert_FRAMEWORKS = CydiaSubstrate Foundation UIKit
trustAlert_CFLAGS = -fno-objc-arc
trustAlert_LDFLAGS = -Wl,-segalign,4000

trustAlert_ARCHS = armv7 arm64
export ARCHS = armv7 arm64

include $(THEOS_MAKE_PATH)/tweak.mk
	
	
all::
	@echo "DONE"
	