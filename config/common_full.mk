# Inherit common Lineage stuff
$(call inherit-product, vendor/amy/config/common_mobile.mk)

PRODUCT_SIZE := full

# Include {Lato,Rubik} fonts
$(call inherit-product-if-exists, external/google-fonts/lato/fonts.mk)
$(call inherit-product-if-exists, external/google-fonts/rubik/fonts.mk)

# Fonts
PRODUCT_PACKAGES += \
    Custom-Fonts \
    fonts_customization.xml \
    LineageLatoFont \
    LineageRubikFont

# Recorder
PRODUCT_PACKAGES += \
    Recorder

$(call inherit-product-if-exists, vendor/amy/config/accents.mk)
