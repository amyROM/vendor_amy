# Inherit mobile full common Lineage stuff
$(call inherit-product, vendor/amy/config/common_mobile_full.mk)

# Inherit tablet common Lineage stuff
$(call inherit-product, vendor/amy/config/tablet.mk)

$(call inherit-product, vendor/amy/config/telephony.mk)
