# Inherit common Lineage stuff
$(call inherit-product, vendor/lineage/config/common_mobile.mk)

PRODUCT_SIZE := full

# Include {Lato,Rubik} fonts
$(call inherit-product-if-exists, external/google-fonts/lato/fonts.mk)
$(call inherit-product-if-exists, external/google-fonts/rubik/fonts.mk)

# Blur
PRODUCT_PRODUCT_PROPERTIES += \
    ro.sf.blurs_are_expensive=1 \
    ro.surface_flinger.supports_background_blur=1

ifneq ($(TARGET_USES_BLUR),true)
PRODUCT_PRODUCT_PROPERTIES += \
    persist.sys.sf.disable_blurs=1
endif

# Fonts
PRODUCT_PACKAGES += \
    fonts_customization.xml \
    LineageLatoFont \
    LineageRubikFont

# Recorder
PRODUCT_PACKAGES += \
    Recorder

# Inherit theme configs
$(call inherit-product, vendor/lineage/config/accents.mk)
$(call inherit-product, vendor/lineage/config/shapes.mk)
