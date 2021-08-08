include vendor/amy/config/BoardConfigKernel.mk

ifeq ($(BOARD_USES_QCOM_HARDWARE),true)
include vendor/amy/config/BoardConfigQcom.mk
endif

include vendor/amy/config/BoardConfigSoong.mk
