# Copyright (C) 2017 Unlegacy-Android
# Copyright (C) 2017,2020 The LineageOS Project
# Copyright (C) 2021 amyROM
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# -----------------------------------------------------------------
# GSI Image

AMY_GSI_NAME := amyROM-$(AMY_VERSION)-system.img
AMY_TARGET_GSI := $(PRODUCT_OUT)/$(AMY_GSI_NAME)

.PHONY: pork
pork: $(INSTALLED_SYSTEMIMAGE_TARGET)
	$(hide) cp $(INSTALLED_SYSTEMIMAGE_TARGET) $(AMY_TARGET_GSI)
	@echo "Package Complete: $(AMY_TARGET_GSI)" >&2
