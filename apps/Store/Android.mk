LOCAL_PATH:= $(call my-dir)
include $(CLEAR_VARS)

LOCAL_MODULE := Store
LOCAL_MODULE_STEM := Store.apk
LOCAL_SRC_FILES := Store.apk
LOCAL_MODULE_TAGS := optional
LOCAL_MODULE_CLASS := ETC
LOCAL_MODULE_PATH := $(TARGET_OUT)/priv-app/Store

include $(BUILD_PREBUILT)
