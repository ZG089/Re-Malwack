LOCAL_PATH := $(call my-dir)
include $(CLEAR_VARS)
LOCAL_MODULE := zygisk_logger
LOCAL_SRC_FILES := module.cpp \
    xhook/xh_core.c \
    xhook/xh_elf.c \
    xhook/xh_log.c \
    xhook/xh_util.c \
    xhook/xh_version.c \
    xhook/xhook.c

LOCAL_C_INCLUDES += $(LOCAL_PATH)/xhook
LOCAL_CPPFLAGS := -std=c++17 -Wall -Werror
LOCAL_LDLIBS := -llog
include $(BUILD_SHARED_LIBRARY)
