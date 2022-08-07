# Inherit full common Lineage stuff
$(call inherit-product, vendor/amy/config/common_full.mk)

# Required packages
PRODUCT_PACKAGES += \
    LatinIME

# Include Lineage LatinIME dictionaries
PRODUCT_PACKAGE_OVERLAYS += vendor/amy/overlay/dictionaries
PRODUCT_ENFORCE_RRO_EXCLUDED_OVERLAYS += vendor/amy/overlay/dictionaries

$(call inherit-product, vendor/amy/config/telephony.mk)
