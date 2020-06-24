export TARGET=iphone:10.3:7.0

#GO_EASY_ON_ME = 1
export COPYFILE_DISABLE=1
override TARGET_STRIP_FLAGS = -u
export TARGET_STRIP_FLAGS
export THEOS_DEVICE_PORT=322
export THEOS_DEVICE_IP=192.168.20.1

include theos/makefiles/common.mk

TWEAK_NAME = miniVKS
miniVKS_FILES = main.x VKS.m API.m VKSResponder.m ui.x unlock_content.x fun.x dont_track_me.x
miniVKS_FRAMEWORKS = UIKit
ARCHS = armv7 arm64
miniVKS_LDFLAGS += -Wl,-segalign,4000

include $(THEOS_MAKE_PATH)/tweak.mk


