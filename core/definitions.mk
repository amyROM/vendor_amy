#
# Copyright (C) 2008 The Android Open Source Project
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
#

##
## Common build system definitions.  Mostly standard
## commands for building various types of targets, which
## are used by others to construct the final targets.
##

# These are variables we use to collect overall lists
# of things being processed.

# Full paths to all of the documentation
ALL_DOCS:=

# The short names of all of the targets in the system.
# For each element of ALL_MODULES, two other variables
# are defined:
#   $(ALL_MODULES.$(target)).BUILT
#   $(ALL_MODULES.$(target)).INSTALLED
# The BUILT variable contains LOCAL_BUILT_MODULE for that
# target, and the INSTALLED variable contains the LOCAL_INSTALLED_MODULE.
# Some targets may have multiple files listed in the BUILT and INSTALLED
# sub-variables.
ALL_MODULES:=

# Full paths to targets that should be added to the "make droid"
# set of installed targets.
ALL_DEFAULT_INSTALLED_MODULES:=

# The list of tags that have been defined by
# LOCAL_MODULE_TAGS.  Each word in this variable maps
# to a corresponding ALL_MODULE_TAGS.<tagname> variable
# that contains all of the INSTALLED_MODULEs with that tag.
ALL_MODULE_TAGS:=

# Similar to ALL_MODULE_TAGS, but contains the short names
# of all targets for a particular tag.  The top-level variable
# won't have the list of tags;  ust ALL_MODULE_TAGS to get
# the list of all known tags.  (This means that this variable
# will always be empty; it's just here as a placeholder for
# its sub-variables.)
ALL_MODULE_NAME_TAGS:=

# Full path to all files that are made by some tool
ALL_GENERATED_SOURCES:=

# Full path to all asm, C, C++, lex and yacc generated C files.
# These all have an order-only dependency on the copied headers
ALL_C_CPP_ETC_OBJECTS:=

# The list of dynamic binaries that haven't been stripped/compressed/etc.
ALL_ORIGINAL_DYNAMIC_BINARIES:=

# These files go into the SDK
ALL_SDK_FILES:=

# Files for dalvik.  This is often build without building the rest of the OS.
INTERNAL_DALVIK_MODULES:=

# All findbugs xml files
ALL_FINDBUGS_FILES:=

# GPL module license files
ALL_GPL_MODULE_LICENSE_FILES:=

# Target and host installed module's dependencies on shared libraries.
# They are list of "<module_name>:<installed_file>:lib1,lib2...".
TARGET_DEPENDENCIES_ON_SHARED_LIBRARIES :=
$(TARGET_2ND_ARCH_VAR_PREFIX)TARGET_DEPENDENCIES_ON_SHARED_LIBRARIES :=
HOST_DEPENDENCIES_ON_SHARED_LIBRARIES :=
$(HOST_2ND_ARCH_VAR_PREFIX)HOST_DEPENDENCIES_ON_SHARED_LIBRARIES :=
HOST_CROSS_DEPENDENCIES_ON_SHARED_LIBRARIES :=
$(HOST_CROSS_2ND_ARCH_VAR_PREFIX)HOST_CROSS_DEPENDENCIES_ON_SHARED_LIBRARIES :=

# Generated class file names for Android resource.
# They are escaped and quoted so can be passed safely to a bash command.
ANDROID_RESOURCE_GENERATED_CLASSES := 'R.class' 'R$$*.class' 'Manifest.class' 'Manifest$$*.class'

# Display names for various build targets
TARGET_DISPLAY := target
AUX_DISPLAY := aux
HOST_DISPLAY := host
HOST_CROSS_DISPLAY := host cross

# All installed initrc files
ALL_INIT_RC_INSTALLED_PAIRS :=

###########################################################
## Debugging; prints a variable list to stdout
###########################################################

# $(1): variable name list, not variable values
define print-vars
$(foreach var,$(1), \
  $(info $(var):) \
  $(foreach word,$($(var)), \
    $(info $(space)$(space)$(word)) \
   ) \
 )
endef

###########################################################
## Evaluates to true if the string contains the word true,
## and empty otherwise
## $(1): a var to test
###########################################################

define true-or-empty
$(filter true, $(1))
endef

###########################################################
## Rule for touching GCNO files.
###########################################################
define gcno-touch-rule
$(2): $(1)
	touch -c $$@
endef

###########################################################

###########################################################
## Retrieve the directory of the current makefile
## Must be called before including any other makefile!!
###########################################################

# Figure out where we are.
define my-dir
$(strip \
  $(eval LOCAL_MODULE_MAKEFILE := $$(lastword $$(MAKEFILE_LIST))) \
  $(if $(filter $(BUILD_SYSTEM)/% $(OUT_DIR)/%,$(LOCAL_MODULE_MAKEFILE)), \
    $(error my-dir must be called before including any other makefile.) \
   , \
    $(patsubst %/,%,$(dir $(LOCAL_MODULE_MAKEFILE))) \
   ) \
 )
endef


###########################################################
## Retrieve a list of all makefiles immediately below some directory
###########################################################

define all-makefiles-under
$(wildcard $(1)/*/Android.mk)
endef

###########################################################
## Look under a directory for makefiles that don't have parent
## makefiles.
###########################################################

# $(1): directory to search under
# Ignores $(1)/Android.mk
define first-makefiles-under
$(shell build/make/tools/findleaves.py $(FIND_LEAVES_EXCLUDES) \
        --mindepth=2 $(addprefix --dir=,$(1)) Android.mk)
endef

###########################################################
## Retrieve a list of all makefiles immediately below your directory
## Must be called before including any other makefile!!
###########################################################

define all-subdir-makefiles
$(call all-makefiles-under,$(call my-dir))
endef

###########################################################
## Look in the named list of directories for makefiles,
## relative to the current directory.
## Must be called before including any other makefile!!
###########################################################

# $(1): List of directories to look for under this directory
define all-named-subdir-makefiles
$(wildcard $(addsuffix /Android.mk, $(addprefix $(call my-dir)/,$(1))))
endef

###########################################################
## Find all of the directories under the named directories with
## the specified name.
## Meant to be used like:
##    INC_DIRS := $(call all-named-dirs-under,inc,.)
###########################################################

define all-named-dirs-under
$(call find-subdir-files,$(2) -type d -name "$(1)")
endef

###########################################################
## Find all the directories under the current directory that
## haves name that match $(1)
###########################################################

define all-subdir-named-dirs
$(call all-named-dirs-under,$(1),.)
endef

###########################################################
## Find all of the files under the named directories with
## the specified name.
## Meant to be used like:
##    SRC_FILES := $(call all-named-files-under,*.h,src tests)
###########################################################

define all-named-files-under
$(call find-files-in-subdirs,$(LOCAL_PATH),"$(1)",$(2))
endef

###########################################################
## Find all of the files under the current directory with
## the specified name.
###########################################################

define all-subdir-named-files
$(call all-named-files-under,$(1),.)
endef

###########################################################
## Find all of the java files under the named directories.
## Meant to be used like:
##    SRC_FILES := $(call all-java-files-under,src tests)
###########################################################

define all-java-files-under
$(call all-named-files-under,*.java,$(1))
endef

###########################################################
## Find all of the java files from here.  Meant to be used like:
##    SRC_FILES := $(call all-subdir-java-files)
###########################################################

define all-subdir-java-files
$(call all-java-files-under,.)
endef

###########################################################
## Find all of the c files under the named directories.
## Meant to be used like:
##    SRC_FILES := $(call all-c-files-under,src tests)
###########################################################

define all-c-files-under
$(call all-named-files-under,*.c,$(1))
endef

###########################################################
## Find all of the c files from here.  Meant to be used like:
##    SRC_FILES := $(call all-subdir-c-files)
###########################################################

define all-subdir-c-files
$(call all-c-files-under,.)
endef

###########################################################
## Find all of the cpp files under the named directories.
## LOCAL_CPP_EXTENSION is respected if set.
## Meant to be used like:
##    SRC_FILES := $(call all-cpp-files-under,src tests)
###########################################################

define all-cpp-files-under
$(sort $(patsubst ./%,%, \
  $(shell cd $(LOCAL_PATH) ; \
          find -L $(1) -name "*$(or $(LOCAL_CPP_EXTENSION),.cpp)" -and -not -name ".*") \
 ))
endef

###########################################################
## Find all of the cpp files from here.  Meant to be used like:
##    SRC_FILES := $(call all-subdir-cpp-files)
###########################################################

define all-subdir-cpp-files
$(call all-cpp-files-under,.)
endef

###########################################################
## Find all files named "I*.aidl" under the named directories,
## which must be relative to $(LOCAL_PATH).  The returned list
## is relative to $(LOCAL_PATH).
###########################################################

define all-Iaidl-files-under
$(call all-named-files-under,I*.aidl,$(1))
endef

###########################################################
## Find all of the "I*.aidl" files under $(LOCAL_PATH).
###########################################################

define all-subdir-Iaidl-files
$(call all-Iaidl-files-under,.)
endef

###########################################################
## Find all files named "*.vts" under the named directories,
## which must be relative to $(LOCAL_PATH).  The returned list
## is relative to $(LOCAL_PATH).
###########################################################

define all-vts-files-under
$(call all-named-files-under,*.vts,$(1))
endef

###########################################################
## Find all of the "*.vts" files under $(LOCAL_PATH).
###########################################################

define all-subdir-vts-files
$(call all-vts-files-under,.)
endef

###########################################################
## Find all of the logtags files under the named directories.
## Meant to be used like:
##    SRC_FILES := $(call all-logtags-files-under,src)
###########################################################

define all-logtags-files-under
$(call all-named-files-under,*.logtags,$(1))
endef

###########################################################
## Find all of the .proto files under the named directories.
## Meant to be used like:
##    SRC_FILES := $(call all-proto-files-under,src)
###########################################################

define all-proto-files-under
$(call all-named-files-under,*.proto,$(1))
endef

###########################################################
## Find all of the RenderScript files under the named directories.
##  Meant to be used like:
##    SRC_FILES := $(call all-renderscript-files-under,src)
###########################################################

define all-renderscript-files-under
$(call find-subdir-files,$(1) \( -name "*.rs" -or -name "*.fs" \) -and -not -name ".*")
endef

###########################################################
## Find all of the S files under the named directories.
## Meant to be used like:
##    SRC_FILES := $(call all-c-files-under,src tests)
###########################################################

define all-S-files-under
$(call all-named-files-under,*.S,$(1))
endef

###########################################################
## Find all of the html files under the named directories.
## Meant to be used like:
##    SRC_FILES := $(call all-html-files-under,src tests)
###########################################################

define all-html-files-under
$(call all-named-files-under,*.html,$(1))
endef

###########################################################
## Find all of the html files from here.  Meant to be used like:
##    SRC_FILES := $(call all-subdir-html-files)
###########################################################

define all-subdir-html-files
$(call all-html-files-under,.)
endef

###########################################################
## Find all of the files matching pattern
##    SRC_FILES := $(call find-subdir-files, <pattern>)
###########################################################

define find-subdir-files
$(sort $(patsubst ./%,%,$(shell cd $(LOCAL_PATH) ; find -L $(1))))
endef

###########################################################
# find the files in the subdirectory $1 of LOCAL_DIR
# matching pattern $2, filtering out files $3
# e.g.
#     SRC_FILES += $(call find-subdir-subdir-files, \
#                         css, *.cpp, DontWantThis.cpp)
###########################################################

define find-subdir-subdir-files
$(sort $(filter-out $(patsubst %,$(1)/%,$(3)),$(patsubst ./%,%,$(shell cd \
            $(LOCAL_PATH) ; find -L $(1) -maxdepth 1 -name $(2)))))
endef

###########################################################
## Find all of the files matching pattern
##    SRC_FILES := $(call all-subdir-java-files)
###########################################################

define find-subdir-assets
$(sort $(if $(1),$(patsubst ./%,%, \
	$(shell if [ -d $(1) ] ; then cd $(1) ; find -L ./ -not -name '.*' -and -type f ; fi)), \
	$(warning Empty argument supplied to find-subdir-assets in $(LOCAL_PATH)) \
))
endef

###########################################################
## Find various file types in a list of directories relative to $(LOCAL_PATH)
###########################################################

define find-other-java-files
$(call all-java-files-under,$(1))
endef

define find-other-html-files
$(call all-html-files-under,$(1))
endef

###########################################################
# Use utility find to find given files in the given subdirs.
# This function uses $(1), instead of LOCAL_PATH as the base.
# $(1): the base dir, relative to the root of the source tree.
# $(2): the file name pattern to be passed to find as "-name".
# $(3): a list of subdirs of the base dir.
# Returns: a list of paths relative to the base dir.
###########################################################

define find-files-in-subdirs
$(sort $(patsubst ./%,%, \
  $(shell cd $(1) ; \
          find -L $(3) -name $(2) -and -not -name ".*") \
 ))
endef

###########################################################
## Scan through each directory of $(1) looking for files
## that match $(2) using $(wildcard).  Useful for seeing if
## a given directory or one of its parents contains
## a particular file.  Returns the first match found,
## starting furthest from the root.
###########################################################

define find-parent-file
$(strip \
  $(eval _fpf := $(sort $(wildcard $(foreach f, $(2), $(strip $(1))/$(f))))) \
  $(if $(_fpf),$(_fpf), \
       $(if $(filter-out ./ .,$(1)), \
             $(call find-parent-file,$(patsubst %/,%,$(dir $(1))),$(2)) \
        ) \
   ) \
)
endef

###########################################################
## Find test data in a form required by LOCAL_TEST_DATA
## $(1): the base dir, relative to the root of the source tree.
## $(3): the file name pattern to be passed to find as "-name"
## $(2): a list of subdirs of the base dir
###########################################################

define find-test-data-in-subdirs
$(foreach f,$(sort $(patsubst ./%,%, \
  $(shell cd $(1) ; \
          find -L $(3) -type f -and -name $(2) -and -not -name ".*") \
)),$(1):$(f))
endef

###########################################################
## Function we can evaluate to introduce a dynamic dependency
###########################################################

define add-dependency
$(1): $(2)
endef

###########################################################
## Reverse order of a list
###########################################################

define reverse-list
$(if $(1),$(call reverse-list,$(wordlist 2,$(words $(1)),$(1)))) $(firstword $(1))
endef

define def-host-aux-target
$(eval _idf_val_:=$(if $(strip $(LOCAL_IS_HOST_MODULE)),HOST,$(if $(strip $(LOCAL_IS_AUX_MODULE)),AUX,))) \
$(_idf_val_)
endef

###########################################################
## Returns correct _idfPrefix from the list:
##   { HOST, HOST_CROSS, AUX, TARGET }
###########################################################
# the following rules checked in order:
# ($1 is in {AUX, HOST_CROSS} => $1;
# ($1 is empty) => TARGET;
# ($2 is not empty) => HOST_CROSS;
# => HOST;
define find-idf-prefix
$(strip \
    $(eval _idf_pfx_:=$(strip $(filter AUX HOST_CROSS,$(1)))) \
    $(eval _idf_pfx_:=$(if $(strip $(1)),$(if $(_idf_pfx_),$(_idf_pfx_),$(if $(strip $(2)),HOST_CROSS,HOST)),TARGET)) \
    $(_idf_pfx_)
)
endef

###########################################################
## The intermediates directory.  Where object files go for
## a given target.  We could technically get away without
## the "_intermediates" suffix on the directory, but it's
## nice to be able to grep for that string to find out if
## anyone's abusing the system.
###########################################################

# $(1): target class, like "APPS"
# $(2): target name, like "NotePad"
# $(3): { HOST, HOST_CROSS, AUX, <empty (TARGET)>, <other non-empty (HOST)> }
# $(4): if non-empty, force the intermediates to be COMMON
# $(5): if non-empty, force the intermediates to be for the 2nd arch
# $(6): if non-empty, force the intermediates to be for the host cross os
define intermediates-dir-for
$(strip \
    $(eval _idfClass := $(strip $(1))) \
    $(if $(_idfClass),, \
        $(error $(LOCAL_PATH): Class not defined in call to intermediates-dir-for)) \
    $(eval _idfName := $(strip $(2))) \
    $(if $(_idfName),, \
        $(error $(LOCAL_PATH): Name not defined in call to intermediates-dir-for)) \
    $(eval _idfPrefix := $(call find-idf-prefix,$(3),$(6))) \
    $(eval _idf2ndArchPrefix := $(if $(strip $(5)),$(TARGET_2ND_ARCH_VAR_PREFIX))) \
    $(if $(filter $(_idfPrefix)-$(_idfClass),$(COMMON_MODULE_CLASSES))$(4), \
        $(eval _idfIntBase := $($(_idfPrefix)_OUT_COMMON_INTERMEDIATES)) \
      ,$(if $(filter $(_idfClass),$(PER_ARCH_MODULE_CLASSES)),\
          $(eval _idfIntBase := $($(_idf2ndArchPrefix)$(_idfPrefix)_OUT_INTERMEDIATES)) \
       ,$(eval _idfIntBase := $($(_idfPrefix)_OUT_INTERMEDIATES)) \
       ) \
     ) \
    $(_idfIntBase)/$(_idfClass)/$(_idfName)_intermediates \
)
endef

# Uses LOCAL_MODULE_CLASS, LOCAL_MODULE, and LOCAL_IS_HOST_MODULE
# to determine the intermediates directory.
#
# $(1): if non-empty, force the intermediates to be COMMON
# $(2): if non-empty, force the intermediates to be for the 2nd arch
# $(3): if non-empty, force the intermediates to be for the host cross os
define local-intermediates-dir
$(strip \
    $(if $(strip $(LOCAL_MODULE_CLASS)),, \
        $(error $(LOCAL_PATH): LOCAL_MODULE_CLASS not defined before call to local-intermediates-dir)) \
    $(if $(strip $(LOCAL_MODULE)),, \
        $(error $(LOCAL_PATH): LOCAL_MODULE not defined before call to local-intermediates-dir)) \
    $(call intermediates-dir-for,$(LOCAL_MODULE_CLASS),$(LOCAL_MODULE),$(call def-host-aux-target),$(1),$(2),$(3)) \
)
endef

###########################################################
## The generated sources directory.  Placing generated
## source files directly in the intermediates directory
## causes problems for multiarch builds, where there are
## two intermediates directories for a single target. Put
## them in a separate directory, and they will be copied to
## each intermediates directory automatically.
###########################################################

# $(1): target class, like "APPS"
# $(2): target name, like "NotePad"
# $(3): { HOST, HOST_CROSS, AUX, <empty (TARGET)>, <other non-empty (HOST)> }
# $(4): if non-empty, force the generated sources to be COMMON
define generated-sources-dir-for
$(strip \
    $(eval _idfClass := $(strip $(1))) \
    $(if $(_idfClass),, \
        $(error $(LOCAL_PATH): Class not defined in call to generated-sources-dir-for)) \
    $(eval _idfName := $(strip $(2))) \
    $(if $(_idfName),, \
        $(error $(LOCAL_PATH): Name not defined in call to generated-sources-dir-for)) \
    $(eval _idfPrefix := $(call find-idf-prefix,$(3),)) \
    $(if $(filter $(_idfPrefix)-$(_idfClass),$(COMMON_MODULE_CLASSES))$(4), \
        $(eval _idfIntBase := $($(_idfPrefix)_OUT_COMMON_GEN)) \
      , \
        $(eval _idfIntBase := $($(_idfPrefix)_OUT_GEN)) \
     ) \
    $(_idfIntBase)/$(_idfClass)/$(_idfName)_intermediates \
)
endef

# Uses LOCAL_MODULE_CLASS, LOCAL_MODULE, and LOCAL_IS_HOST_MODULE
# to determine the generated sources directory.
#
# $(1): if non-empty, force the intermediates to be COMMON
define local-generated-sources-dir
$(strip \
    $(if $(strip $(LOCAL_MODULE_CLASS)),, \
        $(error $(LOCAL_PATH): LOCAL_MODULE_CLASS not defined before call to local-generated-sources-dir)) \
    $(if $(strip $(LOCAL_MODULE)),, \
        $(error $(LOCAL_PATH): LOCAL_MODULE not defined before call to local-generated-sources-dir)) \
    $(call generated-sources-dir-for,$(LOCAL_MODULE_CLASS),$(LOCAL_MODULE),$(call def-host-aux-target),$(1)) \
)
endef

###########################################################
## Convert a list of short module names (e.g., "framework", "Browser")
## into the list of files that are built for those modules.
## NOTE: this won't return reliable results until after all
## sub-makefiles have been included.
## $(1): target list
###########################################################

define module-built-files
$(foreach module,$(1),$(ALL_MODULES.$(module).BUILT))
endef

###########################################################
## Convert a list of short modules names (e.g., "framework", "Browser")
## into the list of files that are installed for those modules.
## NOTE: this won't return reliable results until after all
## sub-makefiles have been included.
## $(1): target list
###########################################################

define module-installed-files
$(foreach module,$(1),$(ALL_MODULES.$(module).INSTALLED))
endef

###########################################################
## Convert a list of short modules names (e.g., "framework", "Browser")
## into the list of files that should be used when linking
## against that module as a public API.
## TODO: Allow this for more than JAVA_LIBRARIES modules
## NOTE: this won't return reliable results until after all
## sub-makefiles have been included.
## $(1): target list
###########################################################

define module-stubs-files
$(foreach module,$(1),$(ALL_MODULES.$(module).STUBS))
endef

###########################################################
## Evaluates to the timestamp file for a doc module, which
## is the dependency that should be used.
## $(1): doc module
###########################################################

define doc-timestamp-for
$(OUT_DOCS)/$(strip $(1))-timestamp
endef


###########################################################
## Convert "core ext framework" to "out/.../javalib.jar ..."
## $(1): library list
## $(2): Non-empty if IS_HOST_MODULE
###########################################################

# Get the jar files (you can pass to "javac -classpath") of static or shared
# Java libraries that you want to link against.
# $(1): library name list
# $(2): Non-empty if IS_HOST_MODULE
define java-lib-files
$(foreach lib,$(1),$(call intermediates-dir-for,JAVA_LIBRARIES,$(lib),$(2),COMMON)/classes.jar)
endef

# Get the header jar files (you can pass to "javac -classpath") of static or shared
# Java libraries that you want to link against.
# $(1): library name list
# $(2): Non-empty if IS_HOST_MODULE
ifneq ($(TURBINE_ENABLED),false)
define java-lib-header-files
$(foreach lib,$(1),$(call intermediates-dir-for,JAVA_LIBRARIES,$(lib),$(2),COMMON)/classes-header.jar)
endef
else
define java-lib-header-files
$(call java-lib-files,$(1),$(2))
endef
endif

# Get the dependency files (you can put on the right side of "|" of a build rule)
# of the Java libraries.
# $(1): library name list
# $(2): Non-empty if IS_HOST_MODULE
# Historically for target Java libraries we used a different file (javalib.jar)
# as the dependency.
# Now we can use classes.jar as dependency, so java-lib-deps is the same
# as java-lib-files.
define java-lib-deps
$(call java-lib-files,$(1),$(2))
endef

# Get the jar files (you can pass to "javac -classpath") of static or shared
# APK libraries that you want to link against.
# $(1): library name list
define app-lib-files
$(foreach lib,$(1),$(call intermediates-dir-for,APPS,$(lib),,COMMON)/classes.jar)
endef

# Get the header jar files (you can pass to "javac -classpath") of static or shared
# APK libraries that you want to link against.
# $(1): library name list
ifneq ($(TURBINE_ENABLED),false)
define app-lib-header-files
$(foreach lib,$(1),$(call intermediates-dir-for,APPS,$(lib),,COMMON)/classes-header.jar)
endef
else
define app-lib-header-files
$(call app-lib-files,$(1))
endef
endif

###########################################################
## Returns true if $(1) and $(2) are equal.  Returns
## the empty string if they are not equal.
###########################################################
define streq
$(strip $(if $(strip $(1)),\
  $(if $(strip $(2)),\
    $(if $(filter-out __,_$(subst $(strip $(1)),,$(strip $(2)))$(subst $(strip $(2)),,$(strip $(1)))_),,true), \
    ),\
  $(if $(strip $(2)),\
    ,\
    true)\
 ))
endef

###########################################################
## Convert "a b c" into "a:b:c"
###########################################################
define normalize-path-list
$(subst $(space),:,$(strip $(1)))
endef

###########################################################
## Convert "a b c" into "a,b,c"
###########################################################
define normalize-comma-list
$(subst $(space),$(comma),$(strip $(1)))
endef

###########################################################
## Read the word out of a colon-separated list of words.
## This has the same behavior as the built-in function
## $(word n,str).
##
## The individual words may not contain spaces.
##
## $(1): 1 based index
## $(2): value of the form a:b:c...
###########################################################

define word-colon
$(word $(1),$(subst :,$(space),$(2)))
endef

###########################################################
## Convert "a=b c= d e = f" into "a=b c=d e=f"
##
## $(1): list to collapse
## $(2): if set, separator word; usually "=", ":", or ":="
##       Defaults to "=" if not set.
###########################################################

define collapse-pairs
$(eval _cpSEP := $(strip $(if $(2),$(2),=)))\
$(subst $(space)$(_cpSEP)$(space),$(_cpSEP),$(strip \
    $(subst $(_cpSEP), $(_cpSEP) ,$(1))))
endef

###########################################################
## Given a list of pairs, if multiple pairs have the same
## first components, keep only the first pair.
##
## $(1): list of pairs
## $(2): the separator word, such as ":", "=", etc.
define uniq-pairs-by-first-component
$(eval _upbfc_fc_set :=)\
$(strip $(foreach w,$(1), $(eval _first := $(word 1,$(subst $(2),$(space),$(w))))\
    $(if $(filter $(_upbfc_fc_set),$(_first)),,$(w)\
        $(eval _upbfc_fc_set += $(_first)))))\
$(eval _upbfc_fc_set :=)\
$(eval _first:=)
endef

###########################################################
## MODULE_TAG set operations
###########################################################

# Given a list of tags, return the targets that specify
# any of those tags.
# $(1): tag list
define modules-for-tag-list
$(sort $(foreach tag,$(1),$(foreach m,$(ALL_MODULE_NAME_TAGS.$(tag)),$(ALL_MODULES.$(m).INSTALLED))))
endef

# Same as modules-for-tag-list, but operates on
# ALL_MODULE_NAME_TAGS.
# $(1): tag list
define module-names-for-tag-list
$(sort $(foreach tag,$(1),$(ALL_MODULE_NAME_TAGS.$(tag))))
endef

# Given an accept and reject list, find the matching
# set of targets.  If a target has multiple tags and
# any of them are rejected, the target is rejected.
# Reject overrides accept.
# $(1): list of tags to accept
# $(2): list of tags to reject
#TODO(dbort): do $(if $(strip $(1)),$(1),$(ALL_MODULE_TAGS))
#TODO(jbq): as of 20100106 nobody uses the second parameter
define get-tagged-modules
$(filter-out \
	$(call modules-for-tag-list,$(2)), \
	    $(call modules-for-tag-list,$(1)))
endef

###########################################################
## Append a leaf to a base path.  Properly deals with
## base paths ending in /.
##
## $(1): base path
## $(2): leaf path
###########################################################

define append-path
$(subst //,/,$(1)/$(2))
endef


###########################################################
## Color-coded warnings and errors
## Use echo-(warning|error) in a build rule
## Use pretty-(warning|error) instead of $(warning)/$(error)
###########################################################
ESC_BOLD := \033[1m
ESC_WARNING := \033[35m
ESC_ERROR := \033[31m
ESC_RESET := \033[0m

# $(1): path (and optionally line) information
# $(2): message to print
define echo-warning
echo -e "$(ESC_BOLD)$(1): $(ESC_WARNING)warning:$(ESC_RESET)$(ESC_BOLD)" $(2) "$(ESC_RESET)" >&2
endef

# $(1): path (and optionally line) information
# $(2): message to print
define echo-error
echo -e "$(ESC_BOLD)$(1): $(ESC_ERROR)error:$(ESC_RESET)$(ESC_BOLD)" $(2) "$(ESC_RESET)" >&2
endef

# $(1): message to print
define pretty-warning
$(shell $(call echo-warning,$(LOCAL_MODULE_MAKEFILE),$(LOCAL_MODULE): $(1)))
endef

# $(1): message to print
define pretty-error
$(shell $(call echo-error,$(LOCAL_MODULE_MAKEFILE),$(LOCAL_MODULE): $(1)))
$(error done)
endef

###########################################################
## Package filtering
###########################################################

# Given a list of installed modules (short or long names)
# return a list of the packages (yes, .apk packages, not
# modules in general) that are overridden by this list and,
# therefore, should not be installed.
# $(1): mixed list of installed modules
# TODO: This is fragile; find a reliable way to get this information.
define _get-package-overrides
 $(eval ### Discard any words containing slashes, unless they end in .apk, \
        ### in which case trim off the directory component and the suffix. \
        ### If there are no slashes, keep the entire word.)
 $(eval _gpo_names := $(subst /,@@@ @@@,$(1)))
 $(eval _gpo_names := \
     $(filter %.apk,$(_gpo_names)) \
     $(filter-out %@@@ @@@%,$(_gpo_names)))
 $(eval _gpo_names := $(patsubst %.apk,%,$(_gpo_names)))
 $(eval _gpo_names := $(patsubst @@@%,%,$(_gpo_names)))

 $(eval ### Remove any remaining words that contain dots.)
 $(eval _gpo_names := $(subst .,@@@ @@@,$(_gpo_names)))
 $(eval _gpo_names := $(filter-out %@@@ @@@%,$(_gpo_names)))

 $(eval ### Now we have a list of any words that could possibly refer to \
        ### packages, although there may be words that do not.  Only \
        ### real packages will be present under PACKAGES.*, though.)
 $(foreach _gpo_name,$(_gpo_names),$(PACKAGES.$(_gpo_name).OVERRIDES))
endef

define get-package-overrides
$(sort $(strip $(call _get-package-overrides,$(1))))
endef

###########################################################
## Output the command lines, or not
###########################################################

ifeq ($(strip $(SHOW_COMMANDS)),)
define pretty
@echo $1
endef
else
define pretty
endef
endif

###########################################################
## Commands for including the dependency files the compiler generates
###########################################################
# $(1): the .P file
# $(2): the main build target
define include-depfile
$(eval $(2) : .KATI_DEPFILE := $1)
endef

# $(1): object files
define include-depfiles-for-objs
$(foreach obj, $(1), $(call include-depfile, $(obj:%.o=%.d), $(obj)))
endef

###########################################################
## Track source files compiled to objects
###########################################################
# $(1): list of sources
# $(2): list of matching objects
define track-src-file-obj
$(eval $(call _track-src-file-obj,$(1)))
endef
define _track-src-file-obj
i := w
$(foreach s,$(1),
my_tracked_src_files += $(s)
my_src_file_obj_$(s) := $$(word $$(words $$(i)),$$(2))
i += w)
endef

# $(1): list of sources
# $(2): list of matching generated sources
define track-src-file-gen
$(eval $(call _track-src-file-gen,$(2)))
endef
define _track-src-file-gen
i := w
$(foreach s,$(1),
my_tracked_gen_files += $(s)
my_src_file_gen_$(s) := $$(word $$(words $$(i)),$$(1))
i += w)
endef

# $(1): list of generated sources
# $(2): list of matching objects
define track-gen-file-obj
$(call track-src-file-obj,$(foreach f,$(1),\
  $(or $(my_src_file_gen_$(f)),$(f))),$(2))
endef

###########################################################
## Commands for running lex
###########################################################

define transform-l-to-c-or-cpp
@echo "Lex: $(PRIVATE_MODULE) <= $<"
@mkdir -p $(dir $@)
$(hide) $(LEX) -o$@ $<
endef

###########################################################
## Commands for running yacc
##
###########################################################

define transform-y-to-c-or-cpp
@echo "Yacc: $(PRIVATE_MODULE) <= $<"
@mkdir -p $(dir $@)
$(YACC) $(PRIVATE_YACCFLAGS) \
  --defines=$(basename $@).h \
  -o $@ $<
endef

###########################################################
## Commands to compile RenderScript to Java
###########################################################

## Merge multiple .d files generated by llvm-rs-cc. This is necessary
## because ninja can handle only a single depfile per build target.
## .d files generated by llvm-rs-cc define .stamp, .bc, and optionally
## .java as build targets. However, there's no way to let ninja know
## dependencies to .bc files and .java files, so we give up build
## targets for them. As we write the .stamp file as the target by
## ourselves, the awk script removes the first lines before the colon
## and append a backslash to the last line to concatenate contents of
## multiple files.
# $(1): .d files to be merged
# $(2): merged .d file
define _merge-renderscript-d
$(hide) echo '$@: $(backslash)' > $2
$(foreach d,$1, \
  $(hide) awk 'start { sub(/( \\)?$$/, " \\"); print } /:/ { start=1 }' < $d >> $2$(newline))
$(hide) echo >> $2
endef

# b/37755219
RS_CC_ASAN_OPTIONS := ASAN_OPTIONS=detect_leaks=0:detect_container_overflow=0

define transform-renderscripts-to-java-and-bc
@echo "RenderScript: $(PRIVATE_MODULE) <= $(PRIVATE_RS_SOURCE_FILES)"
$(hide) rm -rf $(PRIVATE_RS_OUTPUT_DIR)
$(hide) mkdir -p $(PRIVATE_RS_OUTPUT_DIR)/res/raw
$(hide) mkdir -p $(PRIVATE_RS_OUTPUT_DIR)/src
$(hide) $(RS_CC_ASAN_OPTIONS) $(PRIVATE_RS_CC) \
  -o $(PRIVATE_RS_OUTPUT_DIR)/res/raw \
  -p $(PRIVATE_RS_OUTPUT_DIR)/src \
  -d $(PRIVATE_RS_OUTPUT_DIR) \
  -a $@ -MD \
  $(addprefix -target-api , $(PRIVATE_RS_TARGET_API)) \
  $(PRIVATE_RS_FLAGS) \
  $(foreach inc,$(PRIVATE_RS_INCLUDES),$(addprefix -I , $(inc))) \
  $(PRIVATE_RS_SOURCE_FILES)
$(call _merge-renderscript-d,$(PRIVATE_DEP_FILES),$@.d)
$(hide) mkdir -p $(dir $@)
$(hide) touch $@
endef

define transform-bc-to-so
@echo "Renderscript compatibility: $(notdir $@) <= $(notdir $<)"
$(hide) mkdir -p $(dir $@)
$(hide) $(BCC_COMPAT) -O3 -o $(dir $@)/$(notdir $(<:.bc=.o)) -fPIC -shared \
	-rt-path $(RS_PREBUILT_CLCORE) -mtriple $(RS_COMPAT_TRIPLE) $<
$(hide) $(PRIVATE_CXX) -shared -Wl,-soname,$(notdir $@) -nostdlib \
	-Wl,-rpath,\$$ORIGIN/../lib \
	$(dir $@)/$(notdir $(<:.bc=.o)) \
	$(RS_PREBUILT_COMPILER_RT) \
	-o $@ $(TARGET_GLOBAL_LDFLAGS) -Wl,--hash-style=sysv \
	-L $(SOONG_OUT_DIR)/ndk/platforms/android-$(PRIVATE_SDK_VERSION)/arch-$(TARGET_ARCH)/usr/lib64 \
	-L $(SOONG_OUT_DIR)/ndk/platforms/android-$(PRIVATE_SDK_VERSION)/arch-$(TARGET_ARCH)/usr/lib \
	$(call intermediates-dir-for,SHARED_LIBRARIES,libRSSupport)/libRSSupport.so \
	-lm -lc
endef

###########################################################
## Commands to compile RenderScript to C++
###########################################################

define transform-renderscripts-to-cpp-and-bc
@echo "RenderScript: $(PRIVATE_MODULE) <= $(PRIVATE_RS_SOURCE_FILES)"
$(hide) rm -rf $(PRIVATE_RS_OUTPUT_DIR)
$(hide) mkdir -p $(PRIVATE_RS_OUTPUT_DIR)/
$(hide) $(RS_CC_ASAN_OPTIONS) $(PRIVATE_RS_CC) \
  -o $(PRIVATE_RS_OUTPUT_DIR)/ \
  -d $(PRIVATE_RS_OUTPUT_DIR) \
  -a $@ -MD \
  -reflect-c++ \
  $(addprefix -target-api , $(PRIVATE_RS_TARGET_API)) \
  $(PRIVATE_RS_FLAGS) \
  $(addprefix -I , $(PRIVATE_RS_INCLUDES)) \
  $(PRIVATE_RS_SOURCE_FILES)
$(call _merge-renderscript-d,$(PRIVATE_DEP_FILES),$@.d)
$(hide) mkdir -p $(dir $@)
$(hide) touch $@
endef


###########################################################
## Commands for running aidl
###########################################################

define transform-aidl-to-java
@mkdir -p $(dir $@)
@echo "Aidl: $(PRIVATE_MODULE) <= $<"
$(hide) $(AIDL) -d$(patsubst %.java,%.P,$@) $(PRIVATE_AIDL_FLAGS) $< $@
endef
#$(AIDL) $(PRIVATE_AIDL_FLAGS) $< - | indent -nut -br -npcs -l1000 > $@

define transform-aidl-to-cpp
@mkdir -p $(dir $@)
@mkdir -p $(PRIVATE_HEADER_OUTPUT_DIR)
@echo "Generating C++ from AIDL: $(PRIVATE_MODULE) <= $<"
$(hide) $(AIDL_CPP) -d$(basename $@).aidl.d -ninja $(PRIVATE_AIDL_FLAGS) \
    $< $(PRIVATE_HEADER_OUTPUT_DIR) $@
endef

## Given a .aidl file path, generate the rule to compile it a .java file
# $(1): a .aidl source file
# $(2): a directory to place the generated .java files in
# $(3): name of a variable to add the path to the generated source file to
#
# You must call this with $(eval).
define define-aidl-java-rule
define-aidl-java-rule-src := $(patsubst %.aidl,%.java,$(subst ../,dotdot/,$(addprefix $(2)/,$(1))))
$$(define-aidl-java-rule-src) : $(LOCAL_PATH)/$(1) $(AIDL)
	$$(transform-aidl-to-java)
$(3) += $$(define-aidl-java-rule-src)
endef

## Given a .aidl file path generate the rule to compile it a .cpp file.
# $(1): a .aidl source file
# $(2): a directory to place the generated .cpp files in
# $(3): name of a variable to add the path to the generated source file to
#
# You must call this with $(eval).
define define-aidl-cpp-rule
define-aidl-cpp-rule-src := $(patsubst %.aidl,%$(LOCAL_CPP_EXTENSION),$(subst ../,dotdot/,$(addprefix $(2)/,$(1))))
$$(define-aidl-cpp-rule-src) : $(LOCAL_PATH)/$(1) $(AIDL_CPP)
	$$(transform-aidl-to-cpp)
$(3) += $$(define-aidl-cpp-rule-src)
endef

###########################################################
## Commands for running vts
###########################################################

define transform-vts-to-cpp
@mkdir -p $(dir $@)
@mkdir -p $(PRIVATE_HEADER_OUTPUT_DIR)
@echo "Generating C++ from VTS: $(PRIVATE_MODULE) <= $<"
$(hide) $(VTSC) -d$(basename $@).vts.P $(PRIVATE_VTS_FLAGS) \
    $< $(PRIVATE_HEADER_OUTPUT_DIR) $@
endef

## Given a .vts file path generate the rule to compile it a .cpp file.
# $(1): a .vts source file
# $(2): a directory to place the generated .cpp files in
# $(3): name of a variable to add the path to the generated source file to
#
# You must call this with $(eval).
define define-vts-cpp-rule
define-vts-cpp-rule-src := $(patsubst %.vts,%$(LOCAL_CPP_EXTENSION),$(subst ../,dotdot/,$(addprefix $(2)/,$(1))))
$$(define-vts-cpp-rule-src) : $(LOCAL_PATH)/$(1) $(VTSC)
	$$(transform-vts-to-cpp)
$(3) += $$(define-vts-cpp-rule-src)
endef

###########################################################
## Commands for running java-event-log-tags.py
###########################################################

define transform-logtags-to-java
@mkdir -p $(dir $@)
@echo "logtags: $@ <= $<"
$(hide) $(JAVATAGS) -o $@ $< $(PRIVATE_MERGED_TAG)
endef


###########################################################
## Commands for running protoc to compile .proto into .java
###########################################################
# PATH contains HOST_OUT_EXECUTABLES to allow protoc-gen-* plugins

define transform-proto-to-java
@mkdir -p $(dir $@)
@echo "Protoc: $@ <= $(PRIVATE_PROTO_SRC_FILES)"
@rm -rf $(PRIVATE_PROTO_JAVA_OUTPUT_DIR)
@mkdir -p $(PRIVATE_PROTO_JAVA_OUTPUT_DIR)
$(hide) for f in $(PRIVATE_PROTO_SRC_FILES); do \
        PATH=$$PATH:$(HOST_OUT_EXECUTABLES) \
        $(PROTOC) \
        $(addprefix --proto_path=, $(PRIVATE_PROTO_INCLUDES)) \
        $(PRIVATE_PROTO_JAVA_OUTPUT_OPTION)="$(PRIVATE_PROTO_JAVA_OUTPUT_PARAMS):$(PRIVATE_PROTO_JAVA_OUTPUT_DIR)" \
        $(PRIVATE_PROTOC_FLAGS) \
        $$f || exit 33; \
        done
$(hide) touch $@
endef

######################################################################
## Commands for running protoc to compile .proto into .pb.cc (or.pb.c) and .pb.h
######################################################################
# PATH contains HOST_OUT_EXECUTABLES to allow protoc-gen-* plugins

define transform-proto-to-cc
@echo "Protoc: $@ <= $<"
@mkdir -p $(dir $@)
$(hide) \
	PATH=$$PATH:$(HOST_OUT_EXECUTABLES) \
	$(PROTOC) \
	$(addprefix --proto_path=, $(PRIVATE_PROTO_INCLUDES)) \
	$(PRIVATE_PROTOC_FLAGS) \
	$<
@# aprotoc outputs only .cc. Rename it to .cpp if necessary.
$(if $(PRIVATE_RENAME_CPP_EXT),\
  $(hide) mv $(basename $@).cc $@)
endef

###########################################################
## Helper to set include paths form transform-*-to-o
###########################################################
define c-includes
$(addprefix -I , $(PRIVATE_C_INCLUDES)) \
$$(cat $(PRIVATE_IMPORT_INCLUDES))\
$(if $(PRIVATE_NO_DEFAULT_COMPILER_FLAGS),,\
    $(addprefix -I ,\
        $(filter-out $(PRIVATE_C_INCLUDES), \
            $(PRIVATE_GLOBAL_C_INCLUDES))) \
    $(addprefix -isystem ,\
        $(filter-out $(PRIVATE_C_INCLUDES), \
            $(PRIVATE_GLOBAL_C_SYSTEM_INCLUDES))))
endef

###########################################################
## Commands for running gcc to compile a C++ file
###########################################################

define transform-cpp-to-o-compiler-args
	$(c-includes) \
	-c \
	$(if $(PRIVATE_NO_DEFAULT_COMPILER_FLAGS),, \
	    $(PRIVATE_TARGET_GLOBAL_CFLAGS) \
	    $(PRIVATE_TARGET_GLOBAL_CPPFLAGS) \
	    $(PRIVATE_ARM_CFLAGS) \
	 ) \
	$(PRIVATE_RTTI_FLAG) \
	$(PRIVATE_CFLAGS) \
	$(PRIVATE_CPPFLAGS) \
	$(PRIVATE_DEBUG_CFLAGS) \
	$(PRIVATE_CFLAGS_NO_OVERRIDE) \
	$(PRIVATE_CPPFLAGS_NO_OVERRIDE)
endef

define clang-tidy-cpp
$(hide) $(PATH_TO_CLANG_TIDY) $(PRIVATE_TIDY_FLAGS) \
  -checks=$(PRIVATE_TIDY_CHECKS) \
  $< -- $(transform-cpp-to-o-compiler-args)
endef

ifneq (,$(filter 1 true,$(WITH_TIDY_ONLY)))
define transform-cpp-to-o
$(if $(PRIVATE_TIDY_CHECKS),
  @echo "$($(PRIVATE_PREFIX)DISPLAY) tidy $(PRIVATE_ARM_MODE) C++: $<"
  $(clang-tidy-cpp))
endef
else
define transform-cpp-to-o
@echo "$($(PRIVATE_PREFIX)DISPLAY) $(PRIVATE_ARM_MODE) C++: $(PRIVATE_MODULE) <= $<"
@mkdir -p $(dir $@)
$(if $(PRIVATE_TIDY_CHECKS),$(clang-tidy-cpp))
$(hide) $(RELATIVE_PWD) $(PRIVATE_CXX) \
  $(transform-cpp-to-o-compiler-args) \
  -MD -MF $(patsubst %.o,%.d,$@) -o $@ $<
endef
endif


###########################################################
## Commands for running gcc to compile a C file
###########################################################

# $(1): extra flags
define transform-c-or-s-to-o-compiler-args
	$(c-includes) \
	-c \
	$(if $(PRIVATE_NO_DEFAULT_COMPILER_FLAGS),, \
	    $(PRIVATE_TARGET_GLOBAL_CFLAGS) \
	    $(PRIVATE_TARGET_GLOBAL_CONLYFLAGS) \
	    $(PRIVATE_ARM_CFLAGS) \
	 ) \
	 $(1)
endef

define transform-c-to-o-compiler-args
$(call transform-c-or-s-to-o-compiler-args, \
  $(PRIVATE_CFLAGS) \
  $(PRIVATE_CONLYFLAGS) \
  $(PRIVATE_DEBUG_CFLAGS) \
  $(PRIVATE_CFLAGS_NO_OVERRIDE))
endef

define clang-tidy-c
$(hide) $(PATH_TO_CLANG_TIDY) $(PRIVATE_TIDY_FLAGS) \
  -checks=$(PRIVATE_TIDY_CHECKS) \
  $< -- $(transform-c-to-o-compiler-args)
endef

ifneq (,$(filter 1 true,$(WITH_TIDY_ONLY)))
define transform-c-to-o
$(if $(PRIVATE_TIDY_CHECKS),
  @echo "$($(PRIVATE_PREFIX)DISPLAY) tidy $(PRIVATE_ARM_MODE) C: $<"
  $(clang-tidy-c))
endef
else
define transform-c-to-o
@echo "$($(PRIVATE_PREFIX)DISPLAY) $(PRIVATE_ARM_MODE) C: $(PRIVATE_MODULE) <= $<"
@mkdir -p $(dir $@)
$(if $(PRIVATE_TIDY_CHECKS),$(clang-tidy-c))
$(hide) $(RELATIVE_PWD) $(PRIVATE_CC) \
  $(transform-c-to-o-compiler-args) \
  -MD -MF $(patsubst %.o,%.d,$@) -o $@ $<
endef
endif

define transform-s-to-o
@echo "$($(PRIVATE_PREFIX)DISPLAY) asm: $(PRIVATE_MODULE) <= $<"
@mkdir -p $(dir $@)
$(RELATIVE_PWD) $(PRIVATE_CC) \
  $(call transform-c-or-s-to-o-compiler-args, $(PRIVATE_ASFLAGS)) \
  -MD -MF $(patsubst %.o,%.d,$@) -o $@ $<
endef

# YASM compilation
define transform-asm-to-o
@mkdir -p $(dir $@)
$(hide) $(YASM) \
    $(addprefix -I , $(PRIVATE_C_INCLUDES)) \
    $($(PRIVATE_2ND_ARCH_VAR_PREFIX)TARGET_GLOBAL_YASM_FLAGS) \
    $(PRIVATE_ASFLAGS) \
    -o $@ $<
endef

###########################################################
## Commands for running gcc to compile an Objective-C file
## This should never happen for target builds but this
## will error at build time.
###########################################################

define transform-m-to-o
@echo "$($(PRIVATE_PREFIX)DISPLAY) ObjC: $(PRIVATE_MODULE) <= $<"
$(call transform-c-or-s-to-o, $(PRIVATE_CFLAGS) $(PRIVATE_DEBUG_CFLAGS))
endef

###########################################################
## Commands for running gcc to compile a host C++ file
###########################################################

define transform-host-cpp-to-o-compiler-args
	$(c-includes) \
	-c \
	$(if $(PRIVATE_NO_DEFAULT_COMPILER_FLAGS),, \
	    $(PRIVATE_HOST_GLOBAL_CFLAGS) \
	    $(PRIVATE_HOST_GLOBAL_CPPFLAGS) \
	 ) \
	$(PRIVATE_CFLAGS) \
	$(PRIVATE_CPPFLAGS) \
	$(PRIVATE_DEBUG_CFLAGS) \
	$(PRIVATE_CFLAGS_NO_OVERRIDE) \
	$(PRIVATE_CPPFLAGS_NO_OVERRIDE)
endef

define clang-tidy-host-cpp
$(hide) $(PATH_TO_CLANG_TIDY) $(PRIVATE_TIDY_FLAGS) \
  -checks=$(PRIVATE_TIDY_CHECKS) \
  $< -- $(transform-host-cpp-to-o-compiler-args)
endef

ifneq (,$(filter 1 true,$(WITH_TIDY_ONLY)))
define transform-host-cpp-to-o
$(if $(PRIVATE_TIDY_CHECKS),
  @echo "tidy $($(PRIVATE_PREFIX)DISPLAY) C++: $<"
  $(clang-tidy-host-cpp))
endef
else
define transform-host-cpp-to-o
@echo "$($(PRIVATE_PREFIX)DISPLAY) C++: $(PRIVATE_MODULE) <= $<"
@mkdir -p $(dir $@)
$(if $(PRIVATE_TIDY_CHECKS),$(clang-tidy-host-cpp))
$(hide) $(RELATIVE_PWD) $(PRIVATE_CXX) \
  $(transform-host-cpp-to-o-compiler-args) \
  -MD -MF $(patsubst %.o,%.d,$@) -o $@ $<
endef
endif


###########################################################
## Commands for running gcc to compile a host C file
###########################################################

define transform-host-c-or-s-to-o-common-args
	$(c-includes) \
	-c \
	$(if $(PRIVATE_NO_DEFAULT_COMPILER_FLAGS),, \
	    $(PRIVATE_HOST_GLOBAL_CFLAGS) \
	    $(PRIVATE_HOST_GLOBAL_CONLYFLAGS) \
	 )
endef

# $(1): extra flags
define transform-host-c-or-s-to-o
@mkdir -p $(dir $@)
$(hide) $(RELATIVE_PWD) $(PRIVATE_CC) \
  $(transform-host-c-or-s-to-o-common-args) \
  $(1) \
  -MD -MF $(patsubst %.o,%.d,$@) -o $@ $<
endef

define transform-host-c-to-o-compiler-args
  $(transform-host-c-or-s-to-o-common-args) \
  $(PRIVATE_CFLAGS) $(PRIVATE_CONLYFLAGS) \
  $(PRIVATE_DEBUG_CFLAGS) $(PRIVATE_CFLAGS_NO_OVERRIDE)
endef

define clang-tidy-host-c
$(hide) $(PATH_TO_CLANG_TIDY) $(PRIVATE_TIDY_FLAGS) \
  -checks=$(PRIVATE_TIDY_CHECKS) \
  $< -- $(transform-host-c-to-o-compiler-args)
endef

ifneq (,$(filter 1 true,$(WITH_TIDY_ONLY)))
define transform-host-c-to-o
$(if $(PRIVATE_TIDY_CHECKS),
  @echo "tidy $($(PRIVATE_PREFIX)DISPLAY) C: $<"
  $(clang-tidy-host-c))
endef
else
define transform-host-c-to-o
@echo "$($(PRIVATE_PREFIX)DISPLAY) C: $(PRIVATE_MODULE) <= $<"
@mkdir -p $(dir $@)
$(if $(PRIVATE_TIDY_CHECKS), $(clang-tidy-host-c))
$(hide) $(RELATIVE_PWD) $(PRIVATE_CC) \
  $(transform-host-c-to-o-compiler-args) \
  -MD -MF $(patsubst %.o,%.d,$@) -o $@ $<
endef
endif

define transform-host-s-to-o
@echo "$($(PRIVATE_PREFIX)DISPLAY) asm: $(PRIVATE_MODULE) <= $<"
$(call transform-host-c-or-s-to-o, $(PRIVATE_ASFLAGS))
endef

###########################################################
## Commands for running gcc to compile a host Objective-C file
###########################################################

define transform-host-m-to-o
@echo "$($(PRIVATE_PREFIX)DISPLAY) ObjC: $(PRIVATE_MODULE) <= $<"
$(call transform-host-c-or-s-to-o, $(PRIVATE_CFLAGS) $(PRIVATE_DEBUG_CFLAGS) $(PRIVATE_CFLAGS_NO_OVERRIDE))
endef

###########################################################
## Commands for running gcc to compile a host Objective-C++ file
###########################################################

define transform-host-mm-to-o
$(transform-host-cpp-to-o)
endef


###########################################################
## Rules to compile a single C/C++ source with ../ in the path
###########################################################
# Replace "../" in object paths with $(DOTDOT_REPLACEMENT).
DOTDOT_REPLACEMENT := dotdot/

## Rule to compile a C++ source file with ../ in the path.
## Must be called with $(eval).
# $(1): the C++ source file in LOCAL_SRC_FILES.
# $(2): the additional dependencies.
# $(3): the variable name to collect the output object file.
define compile-dotdot-cpp-file
o := $(intermediates)/$(patsubst %$(LOCAL_CPP_EXTENSION),%.o,$(subst ../,$(DOTDOT_REPLACEMENT),$(1)))
$$(o) : $(TOPDIR)$(LOCAL_PATH)/$(1) $(2)
	$$(transform-$$(PRIVATE_HOST)cpp-to-o)
$$(call include-depfiles-for-objs, $$(o))
$(3) += $$(o)
endef

## Rule to compile a C source file with ../ in the path.
## Must be called with $(eval).
# $(1): the C source file in LOCAL_SRC_FILES.
# $(2): the additional dependencies.
# $(3): the variable name to collect the output object file.
define compile-dotdot-c-file
o := $(intermediates)/$(patsubst %.c,%.o,$(subst ../,$(DOTDOT_REPLACEMENT),$(1)))
$$(o) : $(TOPDIR)$(LOCAL_PATH)/$(1) $(2)
	$$(transform-$$(PRIVATE_HOST)c-to-o)
$$(call include-depfiles-for-objs, $$(o))
$(3) += $$(o)
endef

## Rule to compile a .S source file with ../ in the path.
## Must be called with $(eval).
# $(1): the .S source file in LOCAL_SRC_FILES.
# $(2): the additional dependencies.
# $(3): the variable name to collect the output object file.
define compile-dotdot-s-file
o := $(intermediates)/$(patsubst %.S,%.o,$(subst ../,$(DOTDOT_REPLACEMENT),$(1)))
$$(o) : $(TOPDIR)$(LOCAL_PATH)/$(1) $(2)
	$$(transform-$$(PRIVATE_HOST)s-to-o)
$$(call include-depfiles-for-objs, $$(o))
$(3) += $$(o)
endef

## Rule to compile a .s source file with ../ in the path.
## Must be called with $(eval).
# $(1): the .s source file in LOCAL_SRC_FILES.
# $(2): the additional dependencies.
# $(3): the variable name to collect the output object file.
define compile-dotdot-s-file-no-deps
o := $(intermediates)/$(patsubst %.s,%.o,$(subst ../,$(DOTDOT_REPLACEMENT),$(1)))
$$(o) : $(TOPDIR)$(LOCAL_PATH)/$(1) $(2)
	$$(transform-$$(PRIVATE_HOST)s-to-o)
$(3) += $$(o)
endef

###########################################################
## Commands for running ar
###########################################################

define _concat-if-arg2-not-empty
$(if $(2),$(hide) $(1) $(2))
endef

# Split long argument list into smaller groups and call the command repeatedly
# Call the command at least once even if there are no arguments, as otherwise
# the output file won't be created.
#
# $(1): the command without arguments
# $(2): the arguments
define split-long-arguments
$(hide) $(1) $(wordlist 1,500,$(2))
$(call _concat-if-arg2-not-empty,$(1),$(wordlist 501,1000,$(2)))
$(call _concat-if-arg2-not-empty,$(1),$(wordlist 1001,1500,$(2)))
$(call _concat-if-arg2-not-empty,$(1),$(wordlist 1501,2000,$(2)))
$(call _concat-if-arg2-not-empty,$(1),$(wordlist 2001,2500,$(2)))
$(call _concat-if-arg2-not-empty,$(1),$(wordlist 2501,3000,$(2)))
$(call _concat-if-arg2-not-empty,$(1),$(wordlist 3001,99999,$(2)))
endef

# $(1): the full path of the source static library.
# $(2): the full path of the destination static library.
define _extract-and-include-single-target-whole-static-lib
$(hide) ldir=$(PRIVATE_INTERMEDIATES_DIR)/WHOLE/$(basename $(notdir $(1)))_objs;\
    rm -rf $$ldir; \
    mkdir -p $$ldir; \
    cp $(1) $$ldir; \
    lib_to_include=$$ldir/$(notdir $(1)); \
    filelist=; \
    subdir=0; \
    for f in `$($(PRIVATE_2ND_ARCH_VAR_PREFIX)TARGET_AR) t $(1)`; do \
        if [ -e $$ldir/$$f ]; then \
            mkdir $$ldir/$$subdir; \
            ext=$$subdir/; \
            subdir=$$((subdir+1)); \
            $($(PRIVATE_2ND_ARCH_VAR_PREFIX)TARGET_AR) m $$lib_to_include $$f; \
        else \
            ext=; \
        fi; \
        $($(PRIVATE_2ND_ARCH_VAR_PREFIX)TARGET_AR) p $$lib_to_include $$f > $$ldir/$$ext$$f; \
        filelist="$$filelist $$ldir/$$ext$$f"; \
    done ; \
    $($(PRIVATE_2ND_ARCH_VAR_PREFIX)TARGET_AR) $($(PRIVATE_2ND_ARCH_VAR_PREFIX)TARGET_GLOBAL_ARFLAGS) \
        $(PRIVATE_ARFLAGS) $(2) $$filelist

endef

# $(1): the full path of the source static library.
# $(2): the full path of the destination static library.
define extract-and-include-whole-static-libs-first
$(if $(strip $(1)),
$(hide) cp $(1) $(2))
endef

# $(1): the full path of the destination static library.
define extract-and-include-target-whole-static-libs
$(call extract-and-include-whole-static-libs-first, $(firstword $(PRIVATE_ALL_WHOLE_STATIC_LIBRARIES)),$(1))
$(foreach lib,$(wordlist 2,999,$(PRIVATE_ALL_WHOLE_STATIC_LIBRARIES)), \
    $(call _extract-and-include-single-target-whole-static-lib, $(lib), $(1)))
endef

# Explicitly delete the archive first so that ar doesn't
# try to add to an existing archive.
define transform-o-to-static-lib
@echo "$($(PRIVATE_PREFIX)DISPLAY) StaticLib: $(PRIVATE_MODULE) ($@)"
@mkdir -p $(dir $@)
@rm -f $@ $@.tmp
$(call extract-and-include-target-whole-static-libs,$@.tmp)
$(call split-long-arguments,$($(PRIVATE_2ND_ARCH_VAR_PREFIX)TARGET_AR) \
    $($(PRIVATE_2ND_ARCH_VAR_PREFIX)TARGET_GLOBAL_ARFLAGS) \
    $(PRIVATE_ARFLAGS) \
    $@.tmp,$(PRIVATE_ALL_OBJECTS))
$(hide) mv -f $@.tmp $@
endef

# $(1): the full path of the source static library.
# $(2): the full path of the destination static library.
define _extract-and-include-single-aux-whole-static-lib
$(hide) ldir=$(PRIVATE_INTERMEDIATES_DIR)/WHOLE/$(basename $(notdir $(1)))_objs;\
    rm -rf $$ldir; \
    mkdir -p $$ldir; \
    cp $(1) $$ldir; \
    lib_to_include=$$ldir/$(notdir $(1)); \
    filelist=; \
    subdir=0; \
    for f in `$(PRIVATE_AR) t $(1)`; do \
        if [ -e $$ldir/$$f ]; then \
            mkdir $$ldir/$$subdir; \
            ext=$$subdir/; \
            subdir=$$((subdir+1)); \
            $(PRIVATE_AR) m $$lib_to_include $$f; \
        else \
            ext=; \
        fi; \
        $(PRIVATE_AR) p $$lib_to_include $$f > $$ldir/$$ext$$f; \
        filelist="$$filelist $$ldir/$$ext$$f"; \
    done ; \
    $(PRIVATE_AR) $(AUX_GLOBAL_ARFLAGS) $(2) $$filelist

endef

define extract-and-include-aux-whole-static-libs
$(call extract-and-include-whole-static-libs-first, $(firstword $(PRIVATE_ALL_WHOLE_STATIC_LIBRARIES)),$(1))
$(foreach lib,$(wordlist 2,999,$(PRIVATE_ALL_WHOLE_STATIC_LIBRARIES)), \
    $(call _extract-and-include-single-aux-whole-static-lib, $(lib), $(1)))
endef

# Explicitly delete the archive first so that ar doesn't
# try to add to an existing archive.
define transform-o-to-aux-static-lib
@echo "$($(PRIVATE_PREFIX)DISPLAY) StaticLib: $(PRIVATE_MODULE) ($@)"
@mkdir -p $(dir $@)
@rm -f $@ $@.tmp
$(call extract-and-include-aux-whole-static-libs,$@.tmp)
$(call split-long-arguments,$(PRIVATE_AR) \
    $(AUX_GLOBAL_ARFLAGS) $@.tmp,$(PRIVATE_ALL_OBJECTS))
$(hide) mv -f $@.tmp $@
endef

define transform-o-to-aux-executable-inner
$(hide) $(PRIVATE_CXX) -pie \
	-Bdynamic \
	-Wl,--gc-sections \
	$(PRIVATE_ALL_OBJECTS) \
	-Wl,--whole-archive \
	$(PRIVATE_ALL_WHOLE_STATIC_LIBRARIES) \
	-Wl,--no-whole-archive \
	$(PRIVATE_ALL_STATIC_LIBRARIES) \
	$(PRIVATE_LDFLAGS) \
	-o $@
endef

define transform-o-to-aux-executable
@echo "$(AUX_DISPLAY) Executable: $(PRIVATE_MODULE) ($@)"
@mkdir -p $(dir $@)
$(transform-o-to-aux-executable-inner)
endef

define transform-o-to-aux-static-executable-inner
$(hide) $(PRIVATE_CXX) \
	-Bstatic \
	-Wl,--gc-sections \
	$(PRIVATE_ALL_OBJECTS) \
	-Wl,--whole-archive \
	$(PRIVATE_ALL_WHOLE_STATIC_LIBRARIES) \
	-Wl,--no-whole-archive \
	$(PRIVATE_ALL_STATIC_LIBRARIES) \
	$(PRIVATE_LDFLAGS) \
	-Wl,-Map=$(@).map \
	-o $@
endef

define transform-o-to-aux-static-executable
@echo "$(AUX_DISPLAY) StaticExecutable: $(PRIVATE_MODULE) ($@)"
@mkdir -p $(dir $@)
$(transform-o-to-aux-static-executable-inner)
endef

###########################################################
## Commands for running host ar
###########################################################

# $(1): the full path of the source static library.
# $(2): the full path of the destination static library.
define _extract-and-include-single-host-whole-static-lib
$(hide) ldir=$(PRIVATE_INTERMEDIATES_DIR)/WHOLE/$(basename $(notdir $(1)))_objs;\
    rm -rf $$ldir; \
    mkdir -p $$ldir; \
    cp $(1) $$ldir; \
    lib_to_include=$$ldir/$(notdir $(1)); \
    filelist=; \
    subdir=0; \
    for f in `$($(PRIVATE_2ND_ARCH_VAR_PREFIX)$(PRIVATE_PREFIX)AR) t $(1) | \grep '\.o$$'`; do \
        if [ -e $$ldir/$$f ]; then \
           mkdir $$ldir/$$subdir; \
           ext=$$subdir/; \
           subdir=$$((subdir+1)); \
           $($(PRIVATE_2ND_ARCH_VAR_PREFIX)$(PRIVATE_PREFIX)AR) m $$lib_to_include $$f; \
        else \
           ext=; \
        fi; \
        $($(PRIVATE_2ND_ARCH_VAR_PREFIX)$(PRIVATE_PREFIX)AR) p $$lib_to_include $$f > $$ldir/$$ext$$f; \
        filelist="$$filelist $$ldir/$$ext$$f"; \
    done ; \
    $($(PRIVATE_2ND_ARCH_VAR_PREFIX)$(PRIVATE_PREFIX)AR) $($(PRIVATE_2ND_ARCH_VAR_PREFIX)$(PRIVATE_PREFIX)GLOBAL_ARFLAGS) \
        $(2) $$filelist

endef

define extract-and-include-host-whole-static-libs
$(call extract-and-include-whole-static-libs-first, $(firstword $(PRIVATE_ALL_WHOLE_STATIC_LIBRARIES)),$(1))
$(foreach lib,$(wordlist 2,999,$(PRIVATE_ALL_WHOLE_STATIC_LIBRARIES)), \
    $(call _extract-and-include-single-host-whole-static-lib, $(lib),$(1)))
endef

ifeq ($(HOST_OS),darwin)
# On Darwin the host ar fails if there is nothing to add to .a at all.
# We work around by adding a dummy.o and then deleting it.
define create-dummy.o-if-no-objs
$(if $(PRIVATE_ALL_OBJECTS),,$(hide) touch $(dir $(1))dummy.o)
endef

define get-dummy.o-if-no-objs
$(if $(PRIVATE_ALL_OBJECTS),,$(dir $(1))dummy.o)
endef

define delete-dummy.o-if-no-objs
$(if $(PRIVATE_ALL_OBJECTS),,$(hide) $($(PRIVATE_2ND_ARCH_VAR_PREFIX)$(PRIVATE_PREFIX)AR) d $(1) $(dir $(1))dummy.o \
  && rm -f $(dir $(1))dummy.o)
endef
else
create-dummy.o-if-no-objs =
get-dummy.o-if-no-objs =
delete-dummy.o-if-no-objs =
endif  # HOST_OS is darwin

# Explicitly delete the archive first so that ar doesn't
# try to add to an existing archive.
define transform-host-o-to-static-lib
@echo "$($(PRIVATE_PREFIX)DISPLAY) StaticLib: $(PRIVATE_MODULE) ($@)"
@mkdir -p $(dir $@)
@rm -f $@ $@.tmp
$(call extract-and-include-host-whole-static-libs,$@.tmp)
$(call create-dummy.o-if-no-objs,$@.tmp)
$(call split-long-arguments,$($(PRIVATE_2ND_ARCH_VAR_PREFIX)$(PRIVATE_PREFIX)AR) \
    $($(PRIVATE_2ND_ARCH_VAR_PREFIX)$(PRIVATE_PREFIX)GLOBAL_ARFLAGS) $@.tmp,\
    $(PRIVATE_ALL_OBJECTS) $(call get-dummy.o-if-no-objs,$@.tmp))
$(call delete-dummy.o-if-no-objs,$@.tmp)
$(hide) mv -f $@.tmp $@
endef


###########################################################
## Commands for running gcc to link a shared library or package
###########################################################

# ld just seems to be so finicky with command order that we allow
# it to be overriden en-masse see combo/linux-arm.make for an example.
ifneq ($(HOST_CUSTOM_LD_COMMAND),true)
define transform-host-o-to-shared-lib-inner
$(hide) $(PRIVATE_CXX) \
	-Wl,-rpath-link=$($(PRIVATE_2ND_ARCH_VAR_PREFIX)$(PRIVATE_PREFIX)OUT_INTERMEDIATE_LIBRARIES) \
	-Wl,-rpath,\$$ORIGIN/../$(notdir $($(PRIVATE_2ND_ARCH_VAR_PREFIX)$(PRIVATE_PREFIX)OUT_SHARED_LIBRARIES)) \
	-Wl,-rpath,\$$ORIGIN/$(notdir $($(PRIVATE_2ND_ARCH_VAR_PREFIX)$(PRIVATE_PREFIX)OUT_SHARED_LIBRARIES)) \
	-shared -Wl,-soname,$(notdir $@) \
	$(if $(PRIVATE_NO_DEFAULT_COMPILER_FLAGS),, \
	   $(PRIVATE_HOST_GLOBAL_LDFLAGS) \
	) \
	$(PRIVATE_LDFLAGS) \
	$(PRIVATE_ALL_OBJECTS) \
	-Wl,--whole-archive \
	$(PRIVATE_ALL_WHOLE_STATIC_LIBRARIES) \
	-Wl,--no-whole-archive \
	$(if $(PRIVATE_GROUP_STATIC_LIBRARIES),-Wl$(comma)--start-group) \
	$(PRIVATE_ALL_STATIC_LIBRARIES) \
	$(if $(PRIVATE_GROUP_STATIC_LIBRARIES),-Wl$(comma)--end-group) \
	$(if $(filter true,$(NATIVE_COVERAGE)),-lgcov) \
	$(if $(filter true,$(NATIVE_COVERAGE)),$(PRIVATE_HOST_LIBPROFILE_RT)) \
	$(PRIVATE_ALL_SHARED_LIBRARIES) \
	-o $@ \
	$(PRIVATE_LDLIBS)
endef
endif

define transform-host-o-to-shared-lib
@echo "$($(PRIVATE_PREFIX)DISPLAY) SharedLib: $(PRIVATE_MODULE) ($@)"
@mkdir -p $(dir $@)
$(transform-host-o-to-shared-lib-inner)
endef

define transform-host-o-to-package
@echo "$($(PRIVATE_PREFIX)DISPLAY) Package: $(PRIVATE_MODULE) ($@)"
@mkdir -p $(dir $@)
$(transform-host-o-to-shared-lib-inner)
endef


###########################################################
## Commands for running gcc to link a shared library or package
###########################################################

define transform-o-to-shared-lib-inner
$(hide) $(PRIVATE_CXX) \
	-nostdlib -Wl,-soname,$(notdir $@) \
	-Wl,--gc-sections \
	$(if $(filter true,$(PRIVATE_CLANG)),-shared,-Wl$(comma)-shared) \
	$(PRIVATE_TARGET_CRTBEGIN_SO_O) \
	$(PRIVATE_ALL_OBJECTS) \
	-Wl,--whole-archive \
	$(PRIVATE_ALL_WHOLE_STATIC_LIBRARIES) \
	-Wl,--no-whole-archive \
	$(if $(PRIVATE_GROUP_STATIC_LIBRARIES),-Wl$(comma)--start-group) \
	$(PRIVATE_ALL_STATIC_LIBRARIES) \
	$(if $(PRIVATE_GROUP_STATIC_LIBRARIES),-Wl$(comma)--end-group) \
	$(if $(filter true,$(NATIVE_COVERAGE)),$(PRIVATE_TARGET_COVERAGE_LIB)) \
	$(PRIVATE_TARGET_LIBATOMIC) \
	$(PRIVATE_TARGET_LIBGCC) \
	$(PRIVATE_TARGET_GLOBAL_LDFLAGS) \
	$(PRIVATE_LDFLAGS) \
	$(PRIVATE_ALL_SHARED_LIBRARIES) \
	-o $@ \
	$(PRIVATE_TARGET_CRTEND_SO_O) \
	$(PRIVATE_LDLIBS)
endef

define transform-o-to-shared-lib
@echo "$($(PRIVATE_PREFIX)DISPLAY) SharedLib: $(PRIVATE_MODULE) ($@)"
@mkdir -p $(dir $@)
$(transform-o-to-shared-lib-inner)
endef

###########################################################
## Commands for filtering a target executable or library
###########################################################

ifneq ($(TARGET_BUILD_VARIANT),user)
  TARGET_STRIP_EXTRA = && $(PRIVATE_OBJCOPY) --add-gnu-debuglink=$< $@
  TARGET_STRIP_KEEP_SYMBOLS_EXTRA = --add-gnu-debuglink=$<
endif

define transform-to-stripped
@echo "$($(PRIVATE_PREFIX)DISPLAY) Strip: $(PRIVATE_MODULE) ($@)"
@mkdir -p $(dir $@)
$(hide) $(PRIVATE_STRIP) --strip-all $< -o $@ \
  $(if $(PRIVATE_NO_DEBUGLINK),,$(TARGET_STRIP_EXTRA))
endef

define transform-to-stripped-keep-mini-debug-info
@echo "$($(PRIVATE_PREFIX)DISPLAY) Strip (mini debug info): $(PRIVATE_MODULE) ($@)"
@mkdir -p $(dir $@)
$(hide) rm -f $@ $@.dynsyms $@.funcsyms $@.keep_symbols $@.debug $@.mini_debuginfo.xz
if $(PRIVATE_STRIP) --strip-all -R .comment $< -o $@; then \
  $(PRIVATE_OBJCOPY) --only-keep-debug $< $@.debug && \
  $(PRIVATE_NM) -D $< --format=posix --defined-only | awk '{ print $$1 }' | sort >$@.dynsyms && \
  $(PRIVATE_NM) $< --format=posix --defined-only | awk '{ if ($$2 == "T" || $$2 == "t" || $$2 == "D") print $$1 }' | sort >$@.funcsyms && \
  comm -13 $@.dynsyms $@.funcsyms >$@.keep_symbols && \
  $(PRIVATE_OBJCOPY) --rename-section .debug_frame=saved_debug_frame $@.debug $@.mini_debuginfo && \
  $(PRIVATE_OBJCOPY) -S --remove-section .gdb_index --remove-section .comment --keep-symbols=$@.keep_symbols $@.mini_debuginfo && \
  $(PRIVATE_OBJCOPY) --rename-section saved_debug_frame=.debug_frame $@.mini_debuginfo && \
  rm -f $@.mini_debuginfo.xz && \
  xz $@.mini_debuginfo && \
  $(PRIVATE_OBJCOPY) --add-section .gnu_debugdata=$@.mini_debuginfo.xz $@; \
else \
  cp -f $< $@; \
fi
endef

define transform-to-stripped-keep-symbols
@echo "$($(PRIVATE_PREFIX)DISPLAY) Strip (keep symbols): $(PRIVATE_MODULE) ($@)"
@mkdir -p $(dir $@)
$(hide) $(PRIVATE_OBJCOPY) \
    `$(PRIVATE_READELF) -S $< | awk '/.debug_/ {print "-R " $$2}' | xargs` \
    $(TARGET_STRIP_KEEP_SYMBOLS_EXTRA) $< $@
endef

###########################################################
## Commands for packing a target executable or library
###########################################################

define pack-elf-relocations
@echo "$($(PRIVATE_PREFIX)DISPLAY) Pack Relocations: $(PRIVATE_MODULE) ($@)"
$(copy-file-to-target)
$(hide) $(RELOCATION_PACKER) $@
endef

###########################################################
## Commands for running gcc to link an executable
###########################################################

define transform-o-to-executable-inner
$(hide) $(PRIVATE_CXX) -pie \
	-nostdlib -Bdynamic \
	-Wl,-dynamic-linker,$(PRIVATE_LINKER) \
	-Wl,--gc-sections \
	-Wl,-z,nocopyreloc \
	-Wl,-rpath-link=$(PRIVATE_TARGET_OUT_INTERMEDIATE_LIBRARIES) \
	$(PRIVATE_TARGET_CRTBEGIN_DYNAMIC_O) \
	$(PRIVATE_ALL_OBJECTS) \
	-Wl,--whole-archive \
	$(PRIVATE_ALL_WHOLE_STATIC_LIBRARIES) \
	-Wl,--no-whole-archive \
	$(if $(PRIVATE_GROUP_STATIC_LIBRARIES),-Wl$(comma)--start-group) \
	$(PRIVATE_ALL_STATIC_LIBRARIES) \
	$(if $(PRIVATE_GROUP_STATIC_LIBRARIES),-Wl$(comma)--end-group) \
	$(if $(filter true,$(NATIVE_COVERAGE)),$(PRIVATE_TARGET_COVERAGE_LIB)) \
	$(PRIVATE_TARGET_LIBATOMIC) \
	$(PRIVATE_TARGET_LIBGCC) \
	$(PRIVATE_TARGET_GLOBAL_LDFLAGS) \
	$(PRIVATE_LDFLAGS) \
	$(PRIVATE_ALL_SHARED_LIBRARIES) \
	-o $@ \
	$(PRIVATE_TARGET_CRTEND_O) \
	$(PRIVATE_LDLIBS)
endef

define transform-o-to-executable
@echo "$($(PRIVATE_PREFIX)DISPLAY) Executable: $(PRIVATE_MODULE) ($@)"
@mkdir -p $(dir $@)
$(transform-o-to-executable-inner)
endef


###########################################################
## Commands for linking a static executable. In practice,
## we only use this on arm, so the other platforms don't
## have transform-o-to-static-executable defined.
## Clang driver needs -static to create static executable.
## However, bionic/linker uses -shared to overwrite.
## Linker for x86 targets does not allow coexistance of -static and -shared,
## so we add -static only if -shared is not used.
###########################################################

define transform-o-to-static-executable-inner
$(hide) $(PRIVATE_CXX) \
	-nostdlib -Bstatic \
	$(if $(filter $(PRIVATE_LDFLAGS),-shared),,-static) \
	-Wl,--gc-sections \
	-o $@ \
	$(PRIVATE_TARGET_CRTBEGIN_STATIC_O) \
	$(PRIVATE_TARGET_GLOBAL_LDFLAGS) \
	$(PRIVATE_LDFLAGS) \
	$(PRIVATE_ALL_OBJECTS) \
	-Wl,--whole-archive \
	$(PRIVATE_ALL_WHOLE_STATIC_LIBRARIES) \
	-Wl,--no-whole-archive \
	$(filter-out %libcompiler_rt.a,$(filter-out %libc_nomalloc.a,$(filter-out %libc.a,$(PRIVATE_ALL_STATIC_LIBRARIES)))) \
	-Wl,--start-group \
	$(filter %libc.a,$(PRIVATE_ALL_STATIC_LIBRARIES)) \
	$(filter %libc_nomalloc.a,$(PRIVATE_ALL_STATIC_LIBRARIES)) \
	$(if $(filter true,$(NATIVE_COVERAGE)),$(PRIVATE_TARGET_COVERAGE_LIB)) \
	$(PRIVATE_TARGET_LIBATOMIC) \
	$(filter %libcompiler_rt.a,$(PRIVATE_ALL_STATIC_LIBRARIES)) \
	$(PRIVATE_TARGET_LIBGCC) \
	-Wl,--end-group \
	$(PRIVATE_TARGET_CRTEND_O)
endef

define transform-o-to-static-executable
@echo "$($(PRIVATE_PREFIX)DISPLAY) StaticExecutable: $(PRIVATE_MODULE) ($@)"
@mkdir -p $(dir $@)
$(transform-o-to-static-executable-inner)
endef


###########################################################
## Commands for running gcc to link a host executable
###########################################################
ifdef BUILD_HOST_static
HOST_FPIE_FLAGS :=
else
HOST_FPIE_FLAGS := -pie
# Force the correct entry point to workaround a bug in binutils that manifests with -pie
ifeq ($(HOST_CROSS_OS),windows)
HOST_CROSS_FPIE_FLAGS += -Wl,-e_mainCRTStartup
endif
endif

ifneq ($(HOST_CUSTOM_LD_COMMAND),true)
define transform-host-o-to-executable-inner
$(hide) $(PRIVATE_CXX) \
	$(PRIVATE_ALL_OBJECTS) \
	-Wl,--whole-archive \
	$(PRIVATE_ALL_WHOLE_STATIC_LIBRARIES) \
	-Wl,--no-whole-archive \
	$(if $(PRIVATE_GROUP_STATIC_LIBRARIES),-Wl$(comma)--start-group) \
	$(PRIVATE_ALL_STATIC_LIBRARIES) \
	$(if $(PRIVATE_GROUP_STATIC_LIBRARIES),-Wl$(comma)--end-group) \
	$(if $(filter true,$(NATIVE_COVERAGE)),-lgcov) \
	$(if $(filter true,$(NATIVE_COVERAGE)),$(PRIVATE_HOST_LIBPROFILE_RT)) \
	$(PRIVATE_ALL_SHARED_LIBRARIES) \
	-Wl,-rpath-link=$($(PRIVATE_2ND_ARCH_VAR_PREFIX)$(PRIVATE_PREFIX)OUT_INTERMEDIATE_LIBRARIES) \
	$(foreach path,$(PRIVATE_RPATHS), \
	  -Wl,-rpath,\$$ORIGIN/$(path)) \
	$(if $(PRIVATE_NO_DEFAULT_COMPILER_FLAGS),, \
		$(PRIVATE_HOST_GLOBAL_LDFLAGS) \
	) \
	$(PRIVATE_LDFLAGS) \
	-o $@ \
	$(PRIVATE_LDLIBS)
endef
endif

define transform-host-o-to-executable
@echo "$($(PRIVATE_PREFIX)DISPLAY) Executable: $(PRIVATE_MODULE) ($@)"
@mkdir -p $(dir $@)
$(transform-host-o-to-executable-inner)
endef


###########################################################
## Commands for running javac to make .class files
###########################################################

# b/37750224
AAPT_ASAN_OPTIONS := ASAN_OPTIONS=detect_leaks=0

# TODO: Right now we generate the asset resources twice, first as part
# of generating the Java classes, then at the end when packaging the final
# assets.  This should be changed to do one of two things: (1) Don't generate
# any resource files the first time, only create classes during that stage;
# or (2) Don't use the -c flag with the second stage, instead taking the
# resource files from the first stage as additional input.  My original intent
# was to use approach (2), but this requires a little more work in the tool.
# Maybe we should just use approach (1).

# This rule creates the R.java and Manifest.java files, both of which
# are PRODUCT-neutral.  Don't pass PRIVATE_PRODUCT_AAPT_CONFIG to this invocation.
define create-resource-java-files
@mkdir -p $(PRIVATE_SOURCE_INTERMEDIATES_DIR)
@mkdir -p $(dir $(PRIVATE_RESOURCE_PUBLICS_OUTPUT))
$(hide) $(AAPT_ASAN_OPTIONS) $(AAPT) package $(PRIVATE_AAPT_FLAGS) -m \
    $(eval # PRIVATE_PRODUCT_AAPT_CONFIG is intentionally missing-- see comment.) \
    $(addprefix -J , $(PRIVATE_SOURCE_INTERMEDIATES_DIR)) \
    $(addprefix -M , $(PRIVATE_ANDROID_MANIFEST)) \
    $(addprefix -P , $(PRIVATE_RESOURCE_PUBLICS_OUTPUT)) \
    $(addprefix -S , $(PRIVATE_RESOURCE_DIR)) \
    $(addprefix -A , $(PRIVATE_ASSET_DIR)) \
    $(addprefix -I , $(PRIVATE_AAPT_INCLUDES)) \
    $(addprefix -G , $(PRIVATE_PROGUARD_OPTIONS_FILE)) \
    $(addprefix --min-sdk-version , $(PRIVATE_DEFAULT_APP_TARGET_SDK)) \
    $(addprefix --target-sdk-version , $(PRIVATE_DEFAULT_APP_TARGET_SDK)) \
    $(if $(filter --version-code,$(PRIVATE_AAPT_FLAGS)),,--version-code $(PLATFORM_SDK_VERSION)) \
    $(if $(filter --version-name,$(PRIVATE_AAPT_FLAGS)),,--version-name $(APPS_DEFAULT_VERSION_NAME)) \
    $(addprefix --rename-manifest-package , $(PRIVATE_MANIFEST_PACKAGE_NAME)) \
    $(addprefix --rename-instrumentation-target-package , $(PRIVATE_MANIFEST_INSTRUMENTATION_FOR)) \
    --skip-symbols-without-default-localization
# So that we re-run aapt when the list of input files change
$(hide) echo $(PRIVATE_RESOURCE_LIST) >/dev/null
endef

# Search for generated R.java/Manifest.java, copy the found R.java as $1.
# Also copy them to a central 'R' directory to make it easier to add the files to an IDE.
define find-generated-R.java
$(hide) for GENERATED_MANIFEST_FILE in `find $(PRIVATE_SOURCE_INTERMEDIATES_DIR) \
  -name Manifest.java 2> /dev/null`; do \
    dir=`awk '/package/{gsub(/\./,"/",$$2);gsub(/;/,"",$$2);print $$2;exit}' $$GENERATED_MANIFEST_FILE`; \
    mkdir -p $(TARGET_COMMON_OUT_ROOT)/R/$$dir; \
    $(ACP) -fp $$GENERATED_MANIFEST_FILE $(TARGET_COMMON_OUT_ROOT)/R/$$dir; \
  done;
$(hide) for GENERATED_R_FILE in `find $(PRIVATE_SOURCE_INTERMEDIATES_DIR) \
  -name R.java 2> /dev/null`; do \
    dir=`awk '/package/{gsub(/\./,"/",$$2);gsub(/;/,"",$$2);print $$2;exit}' $$GENERATED_R_FILE`; \
    mkdir -p $(TARGET_COMMON_OUT_ROOT)/R/$$dir; \
    $(ACP) -fp $$GENERATED_R_FILE $(TARGET_COMMON_OUT_ROOT)/R/$$dir \
      || exit 31; \
    $(ACP) -fp $$GENERATED_R_FILE $1 || exit 32; \
  done;
@# Ensure that the target file is always created, i.e. also in case we did not
@# enter the GENERATED_R_FILE-loop above. This avoids unnecessary rebuilding.
$(hide) touch $1
endef

###########################################################
# AAPT2 compilation and link
###########################################################
define aapt2-compile-one-resource-file
@mkdir -p $(dir $@)
$(hide) $(AAPT2) compile -o $(dir $@) $(PRIVATE_AAPT2_CFLAGS) --legacy $<
endef

define aapt2-compile-resource-dirs
@mkdir -p $(dir $@)
$(hide) $(AAPT2) compile -o $@ $(addprefix --dir ,$(PRIVATE_SOURCE_RES_DIRS)) \
  $(PRIVATE_AAPT2_CFLAGS) --legacy
endef

# Set up rule to compile one resource file with aapt2.
# Must be called with $(eval).
# $(1): the source file
# $(2): the output file
define aapt2-compile-one-resource-file-rule
$(2) : $(1) $(AAPT2)
	@echo "AAPT2 compile $$@ <- $$<"
	$$(call aapt2-compile-one-resource-file)
endef

# Convert input resource file path to output file path.
# values-[config]/<file>.xml -> values-[config]_<file>.arsc.flat;
# For other resource file, just replace the last "/" with "_" and
# add .flat extension.
#
# $(1): the input resource file path
# $(2): the base dir of the output file path
# Returns: the compiled output file path
define aapt2-compiled-resource-out-file
$(eval _p_w := $(strip $(subst /,$(space),$(dir $(1)))))$(2)/$(subst $(space),/,$(_p_w))_$(if $(filter values%,$(lastword $(_p_w))),$(patsubst %.xml,%.arsc,$(notdir $(1))),$(notdir $(1))).flat
endef

define aapt2-link
@mkdir -p $(dir $@)
$(call dump-words-to-file,$(PRIVATE_RES_FLAT),$(dir $@)aapt2-flat-list)
$(call dump-words-to-file,$(PRIVATE_OVERLAY_FLAT),$(dir $@)aapt2-flat-overlay-list)
$(hide) $(AAPT2) link -o $@ \
  $(PRIVATE_AAPT_FLAGS) \
  $(addprefix --manifest ,$(PRIVATE_ANDROID_MANIFEST)) \
  $(addprefix -I ,$(PRIVATE_AAPT_INCLUDES)) \
  $(addprefix -I ,$(PRIVATE_SHARED_ANDROID_LIBRARIES)) \
  $(addprefix -A ,$(PRIVATE_ASSET_DIR)) \
  $(addprefix --java ,$(PRIVATE_SOURCE_INTERMEDIATES_DIR)) \
  $(addprefix --proguard ,$(PRIVATE_PROGUARD_OPTIONS_FILE)) \
  $(addprefix --min-sdk-version ,$(PRIVATE_DEFAULT_APP_TARGET_SDK)) \
  $(addprefix --target-sdk-version ,$(PRIVATE_DEFAULT_APP_TARGET_SDK)) \
  $(if $(filter --product,$(PRIVATE_AAPT_FLAGS)),,$(addprefix --product ,$(PRIVATE_TARGET_AAPT_CHARACTERISTICS))) \
  $(addprefix -c ,$(PRIVATE_PRODUCT_AAPT_CONFIG)) \
  $(addprefix --preferred-density ,$(PRIVATE_PRODUCT_AAPT_PREF_CONFIG)) \
  $(if $(filter --version-code,$(PRIVATE_AAPT_FLAGS)),,--version-code $(PLATFORM_SDK_VERSION)) \
  $(if $(filter --version-name,$(PRIVATE_AAPT_FLAGS)),,--version-name $(APPS_DEFAULT_VERSION_NAME)) \
  $(addprefix --rename-manifest-package ,$(PRIVATE_MANIFEST_PACKAGE_NAME)) \
  $(addprefix --rename-instrumentation-target-package ,$(PRIVATE_MANIFEST_INSTRUMENTATION_FOR)) \
  -R \@$(dir $@)aapt2-flat-overlay-list \
  \@$(dir $@)aapt2-flat-list
endef

###########################################################
xlint_unchecked := -Xlint:unchecked

# emit-line, <word list>, <output file>
define emit-line
   $(if $(1),echo -n '$(strip $(1)) ' >> $(2))
endef

# dump-words-to-file, <word list>, <output file>
define dump-words-to-file
        @rm -f $(2)
        @touch $(2)
        @$(call emit-line,$(wordlist 1,500,$(1)),$(2))
        @$(call emit-line,$(wordlist 501,1000,$(1)),$(2))
        @$(call emit-line,$(wordlist 1001,1500,$(1)),$(2))
        @$(call emit-line,$(wordlist 1501,2000,$(1)),$(2))
        @$(call emit-line,$(wordlist 2001,2500,$(1)),$(2))
        @$(call emit-line,$(wordlist 2501,3000,$(1)),$(2))
        @$(call emit-line,$(wordlist 3001,3500,$(1)),$(2))
        @$(call emit-line,$(wordlist 3501,4000,$(1)),$(2))
        @$(call emit-line,$(wordlist 4001,4500,$(1)),$(2))
        @$(call emit-line,$(wordlist 4501,5000,$(1)),$(2))
        @$(call emit-line,$(wordlist 5001,5500,$(1)),$(2))
        @$(call emit-line,$(wordlist 5501,6000,$(1)),$(2))
        @$(call emit-line,$(wordlist 6001,6500,$(1)),$(2))
        @$(call emit-line,$(wordlist 6501,7000,$(1)),$(2))
        @$(call emit-line,$(wordlist 7001,7500,$(1)),$(2))
        @$(call emit-line,$(wordlist 7501,8000,$(1)),$(2))
        @$(call emit-line,$(wordlist 8001,8500,$(1)),$(2))
        @$(call emit-line,$(wordlist 8501,9000,$(1)),$(2))
        @$(call emit-line,$(wordlist 9001,9500,$(1)),$(2))
        @$(call emit-line,$(wordlist 9501,10000,$(1)),$(2))
        @$(call emit-line,$(wordlist 10001,10500,$(1)),$(2))
        @$(call emit-line,$(wordlist 10501,11000,$(1)),$(2))
        @$(call emit-line,$(wordlist 11001,11500,$(1)),$(2))
        @$(call emit-line,$(wordlist 11501,12000,$(1)),$(2))
        @$(call emit-line,$(wordlist 12001,12500,$(1)),$(2))
        @$(call emit-line,$(wordlist 12501,13000,$(1)),$(2))
        @$(call emit-line,$(wordlist 13001,13500,$(1)),$(2))
        @$(if $(wordlist 13501,13502,$(1)),$(error Too many words ($(words $(1)))))
endef

# For a list of jar files, unzip them to a specified directory,
# but make sure that no META-INF files come along for the ride,
# unless PRIVATE_DONT_DELETE_JAR_META_INF is set.
#
# $(1): files to unzip
# $(2): destination directory
define unzip-jar-files
  $(hide) for f in $(1); \
  do \
    if [ ! -f $$f ]; then \
      echo Missing file $$f; \
      exit 1; \
    fi; \
    unzip -qo $$f -d $(2); \
    rm -f $(2)/module-info.class; \
  done
  $(if $(PRIVATE_DONT_DELETE_JAR_META_INF),,$(hide) rm -rf $(2)/META-INF)
endef

# Return jar arguments to compress files in a given directory
# $(1): directory
#
# Returns an @-file argument that contains the output of a subshell
# that looks like -C $(1) path/to/file1 -C $(1) path/to/file2
# Also adds "-C out/empty ." which avoids errors in jar when
# there are no files in the directory.
define jar-args-sorted-files-in-directory
    @<(find $(1) -type f | sort | $(JAR_ARGS) $(1); echo "-C $(EMPTY_DIRECTORY) .")
endef

# append additional Java sources(resources/Proto sources, and etc) to $(1).
define fetch-additional-java-source
$(hide) if [ -d "$(PRIVATE_SOURCE_INTERMEDIATES_DIR)" ]; then \
    find $(PRIVATE_SOURCE_INTERMEDIATES_DIR) -name '*.java' -and -not -name '.*' >> $(1); \
fi
$(if $(PRIVATE_HAS_PROTO_SOURCES), \
    $(hide) find $(PRIVATE_PROTO_SOURCE_INTERMEDIATES_DIR) -name '*.java' -and -not -name '.*' >> $(1))
$(if $(PRIVATE_HAS_RS_SOURCES), \
    $(hide) find $(PRIVATE_RS_SOURCE_INTERMEDIATES_DIR) -name '*.java' -and -not -name '.*' >> $(1))
endef

# Some historical notes:
# - below we write the list of java files to java-source-list to avoid argument
#   list length problems with Cygwin
# - we filter out duplicate java file names because eclipse's compiler
#   doesn't like them.
define write-java-source-list
@echo "$($(PRIVATE_PREFIX)DISPLAY) Java source list: $(PRIVATE_MODULE)"
$(hide) rm -f $@
$(call dump-words-to-file,$(sort $(PRIVATE_JAVA_SOURCES)),$@.tmp)
$(call fetch-additional-java-source,$@.tmp)
$(hide) tr ' ' '\n' < $@.tmp | $(NORMALIZE_PATH) | sort -u > $@
endef

# $(1): sharding number.
# $(2): Java source files paths.
define save-sharded-java-source-list
$(java_source_list_file).shard.$(1): $(2) $$(NORMALIZE_PATH)
	@echo "shard java source list: $$@"
	rm -f $$@
	$$(call dump-words-to-file,$(2),$$@.tmp)
	$(hide) tr ' ' '\n' < $$@.tmp | $$(NORMALIZE_PATH) | sort -u > $$@
endef

# Common definition to invoke javac on the host and target.
#
# $(1): javac
# $(2): classpath_libs
define compile-java
$(hide) rm -f $@
$(hide) rm -rf $(PRIVATE_CLASS_INTERMEDIATES_DIR) $(PRIVATE_ANNO_INTERMEDIATES_DIR)
$(hide) mkdir -p $(dir $@)
$(hide) mkdir -p $(PRIVATE_CLASS_INTERMEDIATES_DIR) $(PRIVATE_ANNO_INTERMEDIATES_DIR)
$(hide) if [ -s $(PRIVATE_JAVA_SOURCE_LIST) ] ; then \
    $(SOONG_JAVAC_WRAPPER) $(JAVAC_WRAPPER) $(1) -encoding UTF-8 \
    $(if $(findstring true,$(PRIVATE_WARNINGS_ENABLE)),$(xlint_unchecked),) \
    $(if $(PRIVATE_USE_SYSTEM_MODULES), \
      $(addprefix --system=,$(PRIVATE_SYSTEM_MODULES_DIR)), \
      $(addprefix -bootclasspath ,$(strip \
          $(call normalize-path-list,$(PRIVATE_BOOTCLASSPATH)) \
          $(PRIVATE_EMPTY_BOOTCLASSPATH)))) \
    $(if $(PRIVATE_USE_SYSTEM_MODULES), \
      $(if $(PRIVATE_PATCH_MODULE), \
        --patch-module=$(PRIVATE_PATCH_MODULE)=$(call normalize-path-list,. $(2)))) \
    $(addprefix -classpath ,$(call normalize-path-list,$(strip \
      $(if $(PRIVATE_USE_SYSTEM_MODULES), \
        $(filter-out $(PRIVATE_SYSTEM_MODULES_LIBS),$(PRIVATE_BOOTCLASSPATH))) \
      $(2)))) \
    $(if $(findstring true,$(PRIVATE_WARNINGS_ENABLE)),$(xlint_unchecked),) \
    -d $(PRIVATE_CLASS_INTERMEDIATES_DIR) -s $(PRIVATE_ANNO_INTERMEDIATES_DIR) \
    $(PRIVATE_JAVACFLAGS) \
    \@$(PRIVATE_JAVA_SOURCE_LIST) \
    || ( rm -rf $(PRIVATE_CLASS_INTERMEDIATES_DIR) ; exit 41 ) \
fi
$(if $(PRIVATE_JAVA_LAYERS_FILE), $(hide) build/make/tools/java-layers.py \
    $(PRIVATE_JAVA_LAYERS_FILE) @$(PRIVATE_JAVA_SOURCE_LIST),)
$(if $(PRIVATE_JAR_EXCLUDE_FILES), $(hide) find $(PRIVATE_CLASS_INTERMEDIATES_DIR) \
    -name $(word 1, $(PRIVATE_JAR_EXCLUDE_FILES)) \
    $(addprefix -o -name , $(wordlist 2, 999, $(PRIVATE_JAR_EXCLUDE_FILES))) \
    | xargs rm -rf)
$(if $(PRIVATE_JAR_PACKAGES), \
    $(hide) find $(PRIVATE_CLASS_INTERMEDIATES_DIR) -mindepth 1 -type f \
        $(foreach pkg, $(PRIVATE_JAR_PACKAGES), \
            -not -path $(PRIVATE_CLASS_INTERMEDIATES_DIR)/$(subst .,/,$(pkg))/\*) -delete ; \
        find $(PRIVATE_CLASS_INTERMEDIATES_DIR) -empty -delete)
$(if $(PRIVATE_JAR_EXCLUDE_PACKAGES), $(hide) rm -rf \
    $(foreach pkg, $(PRIVATE_JAR_EXCLUDE_PACKAGES), \
        $(PRIVATE_CLASS_INTERMEDIATES_DIR)/$(subst .,/,$(pkg))))
$(hide) $(JAR) -cf $@ $(call jar-args-sorted-files-in-directory,$(PRIVATE_CLASS_INTERMEDIATES_DIR))
$(if $(PRIVATE_EXTRA_JAR_ARGS),$(call add-java-resources-to,$@))
endef

# $(1): Javac output jar name.
# $(2): Java source list file.
# $(3): Java header libs.
# $(4): Javac sharding number.
# $(5): Javac sources deps (the arg may neeed $$ in case of containing '#')
define create-classes-full-debug.jar
$(1): PRIVATE_JAVACFLAGS := $$(LOCAL_JAVACFLAGS) $$(annotation_processor_flags)
$(1): PRIVATE_JAR_EXCLUDE_FILES := $$(LOCAL_JAR_EXCLUDE_FILES)
$(1): PRIVATE_JAR_PACKAGES := $$(LOCAL_JAR_PACKAGES)
$(1): PRIVATE_JAR_EXCLUDE_PACKAGES := $$(LOCAL_JAR_EXCLUDE_PACKAGES)
$(1): PRIVATE_DONT_DELETE_JAR_META_INF := $$(LOCAL_DONT_DELETE_JAR_META_INF)
$(1): PRIVATE_JAVA_SOURCE_LIST := $(2)
$(1): PRIVATE_ALL_JAVA_HEADER_LIBRARIES := $(3)
$(1): PRIVATE_CLASS_INTERMEDIATES_DIR := $(intermediates.COMMON)/classes$(4)
$(1): PRIVATE_ANNO_INTERMEDIATES_DIR := $(intermediates.COMMON)/anno$(4)
$(1): \
    $(2) \
    $(3) \
    $(5) \
    $$(full_java_bootclasspath_libs) \
    $$(full_java_system_modules_deps) \
    $$(layers_file) \
    $$(annotation_processor_deps) \
    $$(NORMALIZE_PATH) \
    $$(JAR_ARGS) \
    | $$(SOONG_JAVAC_WRAPPER)
	@echo "Target Java: $$@ ($$(PRIVATE_CLASS_INTERMEDIATES_DIR))"
	$$(call compile-java,$$(TARGET_JAVAC),$$(PRIVATE_ALL_JAVA_HEADER_LIBRARIES))
endef

define transform-java-to-header.jar
@echo "$($(PRIVATE_PREFIX)DISPLAY) Turbine: $(PRIVATE_MODULE)"
@mkdir -p $(dir $@)
@rm -rf $(dir $@)/classes-turbine
@mkdir $(dir $@)/classes-turbine
$(hide) if [ -s $(PRIVATE_JAVA_SOURCE_LIST) ] ; then \
    $(JAVA) -jar $(TURBINE) \
    --output $@.premerged --temp_dir $(dir $@)/classes-turbine \
    --sources \@$(PRIVATE_JAVA_SOURCE_LIST) \
    --javacopts $(PRIVATE_JAVACFLAGS) $(COMMON_JDK_FLAGS) \
    $(addprefix --bootclasspath ,$(strip \
         $(call normalize-path-list,$(PRIVATE_BOOTCLASSPATH)) \
         $(PRIVATE_EMPTY_BOOTCLASSPATH))) \
    $(addprefix --classpath ,$(strip \
        $(call normalize-path-list,$(PRIVATE_ALL_JAVA_HEADER_LIBRARIES)))) \
    || ( rm -rf $(dir $@)/classes-turbine ; exit 41 ) && \
    $(MERGE_ZIPS) -j -stripDir META-INF $@.tmp $@.premerged $(call reverse-list,$(PRIVATE_STATIC_JAVA_HEADER_LIBRARIES)) ; \
else \
    $(MERGE_ZIPS) -j -stripDir META-INF $@.tmp $(call reverse-list,$(PRIVATE_STATIC_JAVA_HEADER_LIBRARIES)) ; \
fi
$(hide) $(ZIPTIME) $@.tmp
$(hide) $(call commit-change-for-toc,$@)
endef

# Moves $1.tmp to $1 if necessary. This is designed to be used with
# .KATI_RESTAT. For kati, this function doesn't update the timestamp
# of $1 when $1.tmp is identical to $1 so that ninja won't rebuild
# targets which depend on $1.
define commit-change-for-toc
$(hide) if cmp -s $1.tmp $1 ; then \
 rm $1.tmp ; \
else \
 mv $1.tmp $1 ; \
fi
endef

ifeq (,$(TARGET_BUILD_APPS))

## Rule to create a table of contents from a .dex file.
## Must be called with $(eval).
# $(1): The directory which contains classes*.dex files
define _transform-dex-to-toc
$1/classes.dex.toc: PRIVATE_INPUT_DEX_FILES := $1/classes*.dex
$1/classes.dex.toc: $1/classes.dex $(DEXDUMP)
	@echo Generating TOC: $$@
	$(hide) ANDROID_LOG_TAGS="*:e" $(DEXDUMP) -l xml $$(PRIVATE_INPUT_DEX_FILES) > $$@.tmp
	$$(call commit-change-for-toc,$$@)
endef

## Define a rule which generates .dex.toc and mark it as .KATI_RESTAT.
# $(1): The directory which contains classes*.dex files
define define-dex-to-toc-rule
$(eval $(call _transform-dex-to-toc,$1))\
$(eval .KATI_RESTAT: $1/classes.dex.toc)
endef

else

# Turn off .toc optimization for apps build as we cannot build dexdump.
define define-dex-to-toc-rule
endef

endif  # TARGET_BUILD_APPS


# Takes an sdk version that might be PLATFORM_VERSION_CODENAME (for example P),
# returns a number greater than the highest existing sdk version if it is, or
# the input if it is not.
define codename-or-sdk-to-sdk
$(if $(filter $(1),$(PLATFORM_VERSION_CODENAME)),10000,$(1))
endef

# --add-opens is required because desugar reflects via java.lang.invoke.MethodHandles.Lookup
define desugar-classes-jar
@echo Desugar: $@
@mkdir -p $(dir $@)
$(hide) rm -f $@ $@.tmp
@rm -rf $(dir $@)/desugar_dumped_classes
@mkdir $(dir $@)/desugar_dumped_classes
$(hide) $(JAVA) \
    $(if $(USE_OPENJDK9),--add-opens java.base/java.lang.invoke=ALL-UNNAMED,) \
    -Djdk.internal.lambda.dumpProxyClasses=$(abspath $(dir $@))/desugar_dumped_classes \
    -jar $(DESUGAR) \
    $(addprefix --bootclasspath_entry ,$(PRIVATE_BOOTCLASSPATH)) \
    $(addprefix --classpath_entry ,$(PRIVATE_SHARED_JAVA_HEADER_LIBRARIES)) \
    --min_sdk_version $(call codename-or-sdk-to-sdk,$(PRIVATE_MIN_SDK_VERSION)) \
    --allow_empty_bootclasspath \
    $(if $(filter --core-library,$(PRIVATE_DX_FLAGS)),--core_library) \
    -i $< -o $@.tmp
    mv $@.tmp $@
endef


define transform-classes.jar-to-dex
@echo "target Dex: $(PRIVATE_MODULE)"
@mkdir -p $(dir $@)
$(hide) rm -f $(dir $@)classes*.dex
$(hide) $(DX_COMMAND) \
    --dex --output=$(dir $@) \
    --min-sdk-version=$(PRIVATE_MIN_SDK_VERSION) \
    $(if $(NO_OPTIMIZE_DX), \
        --no-optimize) \
    $(if $(GENERATE_DEX_DEBUG), \
	    --debug --verbose \
	    --dump-to=$(@:.dex=.lst) \
	    --dump-width=1000) \
    $(PRIVATE_DX_FLAGS) \
    $<
endef


define transform-classes-d8.jar-to-dex
@echo "target Dex: $(PRIVATE_MODULE)"
@mkdir -p $(dir $@)
$(hide) rm -f $(dir $@)classes*.dex $(dir $@)d8_input.jar
$(hide) $(ZIP2ZIP) -j -i $< -o $(dir $@)d8_input.jar "**/*.class"
$(hide) $(DX_COMMAND) \
    --output $(dir $@) \
    --min-api $(PRIVATE_MIN_SDK_VERSION) \
    $(subst --main-dex-list=, --main-dex-list , \
        $(filter-out --core-library --multi-dex --minimal-main-dex,$(PRIVATE_DX_FLAGS))) \
    $(dir $@)d8_input.jar
$(hide) rm -f $(dir $@)d8_input.jar
endef

# Create a mostly-empty .jar file that we'll add to later.
# The MacOS jar tool doesn't like creating empty jar files,
# so we need to give it something.
# $(1) package to create
define create-empty-package-at
@mkdir -p $(dir $(1))
$(hide) touch $(dir $(1))zipdummy
$(hide) $(JAR) cf $(1) -C $(dir $(1)) zipdummy
$(hide) zip -qd $(1) zipdummy
$(hide) rm $(dir $(1))zipdummy
endef

# Create a mostly-empty .jar file that we'll add to later.
# The MacOS jar tool doesn't like creating empty jar files,
# so we need to give it something.
define create-empty-package
$(call create-empty-package-at,$@)
endef

# Copy an arhchive file and delete any class files and empty folders inside.
# $(1): the source archive file.
# $(2): the destination archive file.
define initialize-package-file
@mkdir -p $(dir $(2))
$(hide) cp -f $(1) $(2)
$(hide) zip -qd $(2) "*.class" \
    $(if $(strip $(PRIVATE_DONT_DELETE_JAR_DIRS)),,"*/") \
    || true # Ignore the error when nothing to delete.
endef

#TODO: we kinda want to build different asset packages for
#      different configurations, then combine them later (or something).
#      Per-locale, etc.
#      A list of dynamic and static parameters;  build layers for
#      dynamic params that lay over the static ones.
#TODO: update the manifest to point to the package file
#Note that the version numbers are given to aapt as simple default
#values; applications can override these by explicitly stating
#them in their manifest.
define add-assets-to-package
$(hide) $(AAPT_ASAN_OPTIONS) $(AAPT) package -u $(PRIVATE_AAPT_FLAGS) \
    $(addprefix -c , $(PRIVATE_PRODUCT_AAPT_CONFIG)) \
    $(addprefix --preferred-density , $(PRIVATE_PRODUCT_AAPT_PREF_CONFIG)) \
    $(addprefix -M , $(PRIVATE_ANDROID_MANIFEST)) \
    $(addprefix -S , $(PRIVATE_RESOURCE_DIR)) \
    $(addprefix -A , $(PRIVATE_ASSET_DIR)) \
    $(addprefix -I , $(PRIVATE_AAPT_INCLUDES)) \
    $(addprefix --min-sdk-version , $(PRIVATE_DEFAULT_APP_TARGET_SDK)) \
    $(addprefix --target-sdk-version , $(PRIVATE_DEFAULT_APP_TARGET_SDK)) \
    $(if $(filter --product,$(PRIVATE_AAPT_FLAGS)),,$(addprefix --product , $(PRIVATE_TARGET_AAPT_CHARACTERISTICS))) \
    $(if $(filter --version-code,$(PRIVATE_AAPT_FLAGS)),,--version-code $(PLATFORM_SDK_VERSION)) \
    $(if $(filter --version-name,$(PRIVATE_AAPT_FLAGS)),,--version-name $(APPS_DEFAULT_VERSION_NAME)) \
    $(addprefix --rename-manifest-package , $(PRIVATE_MANIFEST_PACKAGE_NAME)) \
    $(addprefix --rename-instrumentation-target-package , $(PRIVATE_MANIFEST_INSTRUMENTATION_FOR)) \
    --skip-symbols-without-default-localization \
    -F $@
# So that we re-run aapt when the list of input files change
$(hide) echo $(PRIVATE_RESOURCE_LIST) >/dev/null
endef

# We need the extra blank line, so that the command will be on a separate line.
# $(1): the ABI name
# $(2): the list of shared libraies
define _add-jni-shared-libs-to-package-per-abi
$(hide) cp $(2) $(dir $@)lib/$(1)

endef

# For apps_only build, don't uncompress/page-align the jni libraries,
# because the apk may be run on older platforms that don't support loading jni directly from apk.
ifdef TARGET_BUILD_APPS
JNI_COMPRESS_FLAGS :=
ZIPALIGN_PAGE_ALIGN_FLAGS :=
else
JNI_COMPRESS_FLAGS := -0
ZIPALIGN_PAGE_ALIGN_FLAGS := -p
endif

define add-jni-shared-libs-to-package
$(hide) rm -rf $(dir $@)lib
$(hide) mkdir -p $(addprefix $(dir $@)lib/,$(PRIVATE_JNI_SHARED_LIBRARIES_ABI))
$(foreach abi,$(PRIVATE_JNI_SHARED_LIBRARIES_ABI),\
  $(call _add-jni-shared-libs-to-package-per-abi,$(abi),\
    $(patsubst $(abi):%,%,$(filter $(abi):%,$(PRIVATE_JNI_SHARED_LIBRARIES)))))
$(hide) (cd $(dir $@) && zip -qrX $(JNI_COMPRESS_FLAGS) $(notdir $@) lib)
$(hide) rm -rf $(dir $@)lib
endef

#TODO: update the manifest to point to the dex file
define add-dex-to-package
$(call add-dex-to-package-arg,$@)
endef

# $(1): the package file.
define add-dex-to-package-arg
$(hide) find $(dir $(PRIVATE_DEX_FILE)) -maxdepth 1 -name "classes*.dex" | sort | xargs zip -qjX $(1)
endef

# Add java resources added by the current module.
# $(1) destination package
#
define add-java-resources-to
$(call dump-words-to-file, $(PRIVATE_EXTRA_JAR_ARGS), $(1).jar-arg-list)
$(hide) $(JAR) uf $(1) @$(1).jar-arg-list
@rm -f $(1).jar-arg-list
endef

# Add resources (non .class files) from a jar to a package
# $(1): the package file
# $(2): the jar file
# $(3): temporary directory
define add-jar-resources-to-package
  rm -rf $(3)
  mkdir -p $(3)
  unzip -qo $(2) -d $(3) $$(zipinfo -1 $(2) | grep -v -E "\.class$$")
  $(JAR) uf $(1) $(call jar-args-sorted-files-in-directory,$(3))
endef

# Sign a package using the specified key/cert.
#
define sign-package
$(call sign-package-arg,$@)
endef

# $(1): the package file we are signing.
define sign-package-arg
$(hide) mv $(1) $(1).unsigned
$(hide) $(JAVA) -Djava.library.path=$(SIGNAPK_JNI_LIBRARY_PATH) -jar $(SIGNAPK_JAR) \
    $(PRIVATE_CERTIFICATE) $(PRIVATE_PRIVATE_KEY) \
    $(PRIVATE_ADDITIONAL_CERTIFICATES) $(1).unsigned $(1).signed
$(hide) mv $(1).signed $(1)
endef

# Align STORED entries of a package on 4-byte boundaries to make them easier to mmap.
#
define align-package
$(hide) if ! $(ZIPALIGN) -c $(ZIPALIGN_PAGE_ALIGN_FLAGS) 4 $@ >/dev/null ; then \
  mv $@ $@.unaligned; \
  $(ZIPALIGN) \
    -f \
    $(ZIPALIGN_PAGE_ALIGN_FLAGS) \
    4 \
    $@.unaligned $@.aligned; \
  mv $@.aligned $@; \
  fi
endef

# Compress a package using the standard gzip algorithm.
define compress-package
$(hide) \
  mv $@ $@.uncompressed; \
  $(MINIGZIP) -c $@.uncompressed > $@.compressed; \
  rm -f $@.uncompressed; \
  mv $@.compressed $@;
endef

# Remove dynamic timestamps from packages
#
define remove-timestamps-from-package
$(hide) $(ZIPTIME) $@
endef

# Uncompress dex files embedded in an apk.
#
define uncompress-dexs
$(hide) if (zipinfo $@ '*.dex' 2>/dev/null | grep -v ' stor ' >/dev/null) ; then \
  tmpdir=$@.tmpdir; \
  rm -rf $$tmpdir && mkdir $$tmpdir; \
  unzip -q $@ '*.dex' -d $$tmpdir && \
  zip -qd $@ '*.dex' && \
  ( cd $$tmpdir && find . -type f | sort | zip -qD -X -0 ../$(notdir $@) -@ ) && \
  rm -rf $$tmpdir; \
  fi
endef

# Uncompress shared libraries embedded in an apk.
#
define uncompress-shared-libs
$(hide) if (zipinfo $@ $(PRIVATE_EMBEDDED_JNI_LIBS) 2>/dev/null | grep -v ' stor ' >/dev/null) ; then \
  rm -rf $(dir $@)uncompressedlibs && mkdir $(dir $@)uncompressedlibs; \
  unzip -q $@ $(PRIVATE_EMBEDDED_JNI_LIBS) -d $(dir $@)uncompressedlibs && \
  zip -qd $@ 'lib/*.so' && \
  ( cd $(dir $@)uncompressedlibs && find lib -type f | sort | zip -qD -X -0 ../$(notdir $@) -@ ) && \
  rm -rf $(dir $@)uncompressedlibs; \
  fi
endef

# TODO(joeo): If we can ever upgrade to post 3.81 make and get the
# new prebuilt rules to work, we should change this to copy the
# resources to the out directory and then copy the resources.

# Note: we intentionally don't clean PRIVATE_CLASS_INTERMEDIATES_DIR
# in transform-java-to-classes for the sake of vm-tests.
define transform-host-java-to-package
@echo "Host Java: $(PRIVATE_MODULE) ($(PRIVATE_CLASS_INTERMEDIATES_DIR))"
$(call compile-java,$(HOST_JAVAC),$(PRIVATE_ALL_JAVA_LIBRARIES))
endef

# Note: we intentionally don't clean PRIVATE_CLASS_INTERMEDIATES_DIR
# in transform-java-to-classes for the sake of vm-tests.
define transform-host-java-to-dalvik-package
@echo "Dalvik Java: $(PRIVATE_MODULE) ($(PRIVATE_CLASS_INTERMEDIATES_DIR))"
$(call compile-java,$(HOST_JAVAC),$(PRIVATE_ALL_JAVA_HEADER_LIBRARIES))
endef

###########################################################
## Commands for copying files
###########################################################

# Define a rule to copy a header.  Used via $(eval) by copy_headers.make.
# $(1): source header
# $(2): destination header
define copy-one-header
$(2): $(1)
	@echo "Header: $$@"
	$$(copy-file-to-new-target-with-cp)
endef

# Define a rule to copy a file.  For use via $(eval).
# $(1): source file
# $(2): destination file
define copy-one-file
$(2): $(1)
	@echo "Copy: $$@"
	$$(copy-file-to-target)
endef

define copy-and-uncompress-dexs
$(2): $(1) $(ZIPALIGN)
	@echo "Uncompress dexs in: $$@"
	$$(copy-file-to-target)
	$$(uncompress-dexs)
	$$(align-package)
endef

# Copies many files.
# $(1): The files to copy.  Each entry is a ':' separated src:dst pair
# Evaluates to the list of the dst files (ie suitable for a dependency list)
define copy-many-files
$(foreach f, $(1), $(strip \
    $(eval _cmf_tuple := $(subst :, ,$(f))) \
    $(eval _cmf_src := $(word 1,$(_cmf_tuple))) \
    $(eval _cmf_dest := $(word 2,$(_cmf_tuple))) \
    $(eval $(call copy-one-file,$(_cmf_src),$(_cmf_dest))) \
    $(_cmf_dest)))
endef

# Copy the file only if it's a well-formed xml file. For use via $(eval).
# $(1): source file
# $(2): destination file, must end with .xml.
define copy-xml-file-checked
$(2): $(1)
	@echo "Copy xml: $$@"
	$(hide) xmllint $$< >/dev/null  # Don't print the xml file to stdout.
	$$(copy-file-to-target)
endef

# The -t option to acp and the -p option to cp is
# required for OSX.  OSX has a ridiculous restriction
# where it's an error for a .a file's modification time
# to disagree with an internal timestamp, and this
# macro is used to install .a files (among other things).

# Copy a single file from one place to another,
# preserving permissions and overwriting any existing
# file.
# When we used acp, it could not handle high resolution timestamps
# on file systems like ext4. Because of that, '-t' option was disabled
# and copy-file-to-target was identical to copy-file-to-new-target.
# Keep the behavior until we audit and ensure that switching this back
# won't break anything.
define copy-file-to-target
@mkdir -p $(dir $@)
$(hide) rm -f $@
$(hide) cp "$<" "$@"
endef

# The same as copy-file-to-target, but use the local
# cp command instead of acp.
define copy-file-to-target-with-cp
@mkdir -p $(dir $@)
$(hide) rm -f $@
$(hide) cp -p "$<" "$@"
endef

# The same as copy-file-to-target, but strip out "# comment"-style
# comments (for config files and such).
define copy-file-to-target-strip-comments
@mkdir -p $(dir $@)
$(hide) rm -f $@
$(hide) sed -e 's/#.*$$//' -e 's/[ \t]*$$//' -e '/^$$/d' < $< > $@
endef

# The same as copy-file-to-target, but don't preserve
# the old modification time.
define copy-file-to-new-target
@mkdir -p $(dir $@)
$(hide) rm -f $@
$(hide) cp $< $@
endef

# The same as copy-file-to-new-target, but use the local
# cp command instead of acp.
define copy-file-to-new-target-with-cp
@mkdir -p $(dir $@)
$(hide) rm -f $@
$(hide) cp $< $@
endef

# Copy a prebuilt file to a target location.
define transform-prebuilt-to-target
@echo "$($(PRIVATE_PREFIX)DISPLAY) Prebuilt: $(PRIVATE_MODULE) ($@)"
$(copy-file-to-target)
endef

# Copy a prebuilt file to a target location, stripping "# comment" comments.
define transform-prebuilt-to-target-strip-comments
@echo "$($(PRIVATE_PREFIX)DISPLAY) Prebuilt: $(PRIVATE_MODULE) ($@)"
$(copy-file-to-target-strip-comments)
endef

# Copy a list of files/directories to target location, with sub dir structure preserved.
# For example $(HOST_OUT_EXECUTABLES)/aapt -> $(staging)/bin/aapt .
# $(1): the source list of files/directories.
# $(2): the path prefix to strip. In the above example it would be $(HOST_OUT).
# $(3): the target location.
define copy-files-with-structure
$(foreach t,$(1),\
  $(eval s := $(patsubst $(2)%,%,$(t)))\
  $(hide) mkdir -p $(dir $(3)/$(s)); cp -Rf $(t) $(3)/$(s)$(newline))
endef

# Define a rule to create a symlink to a file.
# $(1): full path to source
# $(2): source (may be relative)
# $(3): full path to destination
define symlink-file
$(eval $(_symlink-file))
endef

# Order-only dependency because make/ninja will follow the link when checking
# the timestamp, so the file must exist
define _symlink-file
$(3): | $(1)
	@echo "Symlink: $$@ -> $(2)"
	@mkdir -p $(dir $$@)
	@rm -rf $$@
	$(hide) ln -sf $(2) $$@
endef

# Copy an apk to a target location while removing classes*.dex
# $(1): source file
# $(2): destination file
# $(3): LOCAL_DEX_PREOPT, if nostripping then leave classes*.dex
define dexpreopt-copy-jar
$(2): $(1)
	@echo "Copy: $$@"
	$$(copy-file-to-target)
	$(if $(filter nostripping,$(3)),,$$(call dexpreopt-remove-classes.dex,$$@))
endef

# $(1): the .jar or .apk to remove classes.dex. Note that if all dex files
# are uncompressed in the archive, then dexopt will not do a copy of the dex
# files and we should not strip.
define dexpreopt-remove-classes.dex
$(hide) if (zipinfo $1 '*.dex' 2>/dev/null | grep -v ' stor ' >/dev/null) ; then \
zip --quiet --delete $(1) classes.dex; \
dex_index=2; \
while zip --quiet --delete $(1) classes$${dex_index}.dex > /dev/null; do \
  let dex_index=dex_index+1; \
done \
fi
endef

define hiddenapi-copy-dex-files
$(2): $(1) $(HIDDENAPI) $(INTERNAL_PLATFORM_HIDDENAPI_LIGHT_GREYLIST) \
      $(INTERNAL_PLATFORM_HIDDENAPI_DARK_GREYLIST) $(INTERNAL_PLATFORM_HIDDENAPI_BLACKLIST)
	@rm -rf $(dir $(2))
	@mkdir -p $(dir $(2))
	find $(dir $(1)) -maxdepth 1 -name "classes*.dex" | sort | \
		xargs -I{} cp -f {} $(dir $(2))
	find $(dir $(2)) -name "classes*.dex" | sort | sed 's/^/--dex=/' | \
		xargs $(HIDDENAPI) --light-greylist=$(INTERNAL_PLATFORM_HIDDENAPI_LIGHT_GREYLIST) \
		                   --dark-greylist=$(INTERNAL_PLATFORM_HIDDENAPI_DARK_GREYLIST) \
		                   --blacklist=$(INTERNAL_PLATFORM_HIDDENAPI_BLACKLIST)
endef

define hiddenapi-copy-soong-jar
$(2): PRIVATE_FOLDER := $(dir $(2))dex-hiddenapi
$(2): $(1) $(HIDDENAPI) $(SOONG_ZIP) $(MERGE_ZIPS) $(INTERNAL_PLATFORM_HIDDENAPI_LIGHT_GREYLIST) \
      $(INTERNAL_PLATFORM_HIDDENAPI_DARK_GREYLIST) $(INTERNAL_PLATFORM_HIDDENAPI_BLACKLIST)
	@echo "Hidden API: $$@"
	$$(copy-file-to-target)
	@rm -rf $${PRIVATE_FOLDER}
	@mkdir -p $${PRIVATE_FOLDER}
	unzip -q $(2) 'classes*.dex' -d $${PRIVATE_FOLDER}
	find $${PRIVATE_FOLDER} -name "classes*.dex" | sort | sed 's/^/--dex=/' | \
		xargs $(HIDDENAPI) --light-greylist=$(INTERNAL_PLATFORM_HIDDENAPI_LIGHT_GREYLIST) \
		                   --dark-greylist=$(INTERNAL_PLATFORM_HIDDENAPI_DARK_GREYLIST) \
		                   --blacklist=$(INTERNAL_PLATFORM_HIDDENAPI_BLACKLIST)
	$(SOONG_ZIP) -o $${PRIVATE_FOLDER}/classes.dex.jar -C $${PRIVATE_FOLDER} -D $${PRIVATE_FOLDER}
	$(MERGE_ZIPS) -D -zipToNotStrip $${PRIVATE_FOLDER}/classes.dex.jar -stripFile "classes*.dex" \
		$(2) $${PRIVATE_FOLDER}/classes.dex.jar $(1)
endef

###########################################################
## Commands to call Proguard
###########################################################
ifdef TARGET_OPENJDK9
define transform-jar-to-proguard
@echo Skipping Proguard: $< $@
$(hide) cp '$<' $@
endef
else
define transform-jar-to-proguard
@echo Proguard: $@
$(hide) $(PROGUARD) -injars $< -outjars $@ $(PRIVATE_PROGUARD_FLAGS) \
    $(addprefix -injars , $(PRIVATE_EXTRA_INPUT_JAR))
endef
endif


###########################################################
## Commands to call R8
###########################################################
define transform-jar-to-dex-r8
@echo R8: $@
$(hide) $(R8_COMPAT_PROGUARD) -injars '$<' \
    --min-api $(PRIVATE_MIN_SDK_VERSION) \
    --force-proguard-compatibility --output $(subst classes.dex,,$@) \
    $(PRIVATE_PROGUARD_FLAGS) \
    $(addprefix -injars , $(PRIVATE_EXTRA_INPUT_JAR)) \
    $(PRIVATE_DX_FLAGS)
endef

###########################################################
## Stuff source generated from one-off tools
###########################################################

define transform-generated-source
@echo "$($(PRIVATE_PREFIX)DISPLAY) Generated: $(PRIVATE_MODULE) <= $<"
@mkdir -p $(dir $@)
$(hide) $(PRIVATE_CUSTOM_TOOL)
endef


###########################################################
## Assertions about attributes of the target
###########################################################

# $(1): The file to check
ifndef get-file-size
$(error HOST_OS must define get-file-size)
endif

# $(1): The file(s) to check (often $@)
# $(2): The partition size.
define assert-max-image-size
$(if $(2), \
  size=$$(for i in $(1); do $(call get-file-size,$$i); echo +; done; echo 0); \
  total=$$(( $$( echo "$$size" ) )); \
  printname=$$(echo -n "$(1)" | tr " " +); \
  maxsize=$$(($(2))); \
  if [ "$$total" -gt "$$maxsize" ]; then \
    echo "error: $$printname too large ($$total > $$maxsize)"; \
    false; \
  elif [ "$$total" -gt $$((maxsize - 32768)) ]; then \
    echo "WARNING: $$printname approaching size limit ($$total now; limit $$maxsize)"; \
  fi \
 , \
  true \
 )
endef


###########################################################
## Define device-specific radio files
###########################################################
INSTALLED_RADIOIMAGE_TARGET :=

# Copy a radio image file to the output location, and add it to
# INSTALLED_RADIOIMAGE_TARGET.
# $(1): filename
define add-radio-file
  $(eval $(call add-radio-file-internal,$(1),$(notdir $(1))))
endef
define add-radio-file-internal
INSTALLED_RADIOIMAGE_TARGET += $$(PRODUCT_OUT)/$(2)
$$(PRODUCT_OUT)/$(2) : $$(LOCAL_PATH)/$(1)
	$$(transform-prebuilt-to-target)
endef

# Version of add-radio-file that also arranges for the version of the
# file to be checked against the contents of
# $(TARGET_BOARD_INFO_FILE).
# $(1): filename
# $(2): name of version variable in board-info (eg, "version-baseband")
define add-radio-file-checked
  $(eval $(call add-radio-file-checked-internal,$(1),$(notdir $(1)),$(2)))
endef
define add-radio-file-checked-internal
INSTALLED_RADIOIMAGE_TARGET += $$(PRODUCT_OUT)/$(2)
BOARD_INFO_CHECK += $(3):$(LOCAL_PATH)/$(1)
$$(PRODUCT_OUT)/$(2) : $$(LOCAL_PATH)/$(1)
	$$(transform-prebuilt-to-target)
endef


###########################################################
# Override the package defined in $(1), setting the
# variables listed below differently.
#
#  $(1): The makefile to override (relative to the source
#        tree root)
#  $(2): Old LOCAL_PACKAGE_NAME value.
#  $(3): New LOCAL_PACKAGE_NAME value.
#  $(4): New LOCAL_MANIFEST_PACKAGE_NAME value.
#  $(5): New LOCAL_CERTIFICATE value.
#  $(6): New LOCAL_INSTRUMENTATION_FOR value.
#  $(7): New LOCAL_MANIFEST_INSTRUMENTATION_FOR value.
#
# Note that LOCAL_PACKAGE_OVERRIDES is NOT cleared in
# clear_vars.mk.
###########################################################
define inherit-package
  $(eval $(call inherit-package-internal,$(1),$(2),$(3),$(4),$(5),$(6),$(7)))
endef

define inherit-package-internal
  LOCAL_PACKAGE_OVERRIDES \
      := $(strip $(1))||$(strip $(2))||$(strip $(3))||$(strip $(4))||&&$(strip $(5))||&&$(strip $(6))||&&$(strip $(7)) $(LOCAL_PACKAGE_OVERRIDES)
  include $(1)
  LOCAL_PACKAGE_OVERRIDES \
      := $(wordlist 1,$(words $(LOCAL_PACKAGE_OVERRIDES)), $(LOCAL_PACKAGE_OVERRIDES))
endef

# To be used with inherit-package above
# Evalutes to true if the package was overridden
define set-inherited-package-variables
$(strip $(call set-inherited-package-variables-internal))
endef

define keep-or-override
$(eval $(1) := $(if $(2),$(2),$($(1))))
endef

define set-inherited-package-variables-internal
  $(eval _o := $(subst ||, ,$(lastword $(LOCAL_PACKAGE_OVERRIDES))))
  $(eval _n := $(subst ||, ,$(firstword $(LOCAL_PACKAGE_OVERRIDES))))
  $(if $(filter $(word 2,$(_n)),$(LOCAL_PACKAGE_NAME)), \
    $(eval LOCAL_PACKAGE_NAME := $(word 3,$(_o))) \
    $(eval LOCAL_MANIFEST_PACKAGE_NAME := $(word 4,$(_o))) \
    $(call keep-or-override,LOCAL_CERTIFICATE,$(patsubst &&%,%,$(word 5,$(_o)))) \
    $(call keep-or-override,LOCAL_INSTRUMENTATION_FOR,$(patsubst &&%,%,$(word 6,$(_o)))) \
    $(call keep-or-override,LOCAL_MANIFEST_INSTRUMENTATION_FOR,$(patsubst &&%,%,$(word 7,$(_o)))) \
    $(eval LOCAL_OVERRIDES_PACKAGES := $(sort $(LOCAL_OVERRIDES_PACKAGES) $(word 2,$(_o)))) \
    true \
  ,)
endef

###########################################################
## API Check
###########################################################

# eval this to define a rule that runs apicheck.
#
# Args:
#    $(1)  target
#    $(2)  stable api file
#    $(3)  api file to be tested
#    $(4)  stable removed api file
#    $(5)  removed api file to be tested
#    $(6)  arguments for apicheck
#    $(7)  command to run if apicheck failed
#    $(8)  target dependent on this api check
#    $(9)  additional dependencies
define check-api
$(TARGET_OUT_COMMON_INTERMEDIATES)/PACKAGING/$(strip $(1))-timestamp: $(2) $(3) $(4) $(APICHECK) $(9)
	@echo "Checking API:" $(1)
	$(hide) ( $(APICHECK_COMMAND) $(6) $(2) $(3) $(4) $(5) || ( $(7) ; exit 38 ) )
	$(hide) mkdir -p $$(dir $$@)
	$(hide) touch $$@
$(8): $(TARGET_OUT_COMMON_INTERMEDIATES)/PACKAGING/$(strip $(1))-timestamp
endef

## Whether to build from source if prebuilt alternative exists
###########################################################
# $(1): module name
# $(2): LOCAL_PATH
# Expands to empty string if not from source.
ifeq (true,$(ANDROID_BUILD_FROM_SOURCE))
define if-build-from-source
true
endef
else
define if-build-from-source
$(if $(filter $(ANDROID_NO_PREBUILT_MODULES),$(1))$(filter \
    $(addsuffix %,$(ANDROID_NO_PREBUILT_PATHS)),$(2)),true)
endef
endif

# Include makefile $(1) if build from source for module $(2)
# $(1): the makefile to include
# $(2): module name
# $(3): LOCAL_PATH
define include-if-build-from-source
$(if $(call if-build-from-source,$(2),$(3)),$(eval include $(1)))
endef

# Return the arch for the source file of a prebuilt
# Return "none" if no matching arch found and return empty
# if the input is empty, so the result can be passed to
# LOCAL_MODULE_TARGET_ARCH.
# $(1) the list of archs supported by the prebuilt
define get-prebuilt-src-arch
$(strip $(if $(filter $(TARGET_ARCH),$(1)),$(TARGET_ARCH),\
  $(if $(filter $(TARGET_2ND_ARCH),$(1)),$(TARGET_2ND_ARCH),$(if $(1),none))))
endef

# ###############################################################
# Set up statistics gathering
# ###############################################################
STATS.MODULE_TYPE := \
  HOST_STATIC_LIBRARY \
  HOST_SHARED_LIBRARY \
  STATIC_LIBRARY \
  SHARED_LIBRARY \
  EXECUTABLE \
  HOST_EXECUTABLE \
  PACKAGE \
  PHONY_PACKAGE \
  HOST_PREBUILT \
  PREBUILT \
  MULTI_PREBUILT \
  JAVA_LIBRARY \
  STATIC_JAVA_LIBRARY \
  HOST_JAVA_LIBRARY \
  DROIDDOC \
  COPY_HEADERS \
  NATIVE_TEST \
  NATIVE_BENCHMARK \
  HOST_NATIVE_TEST \
  FUZZ_TEST \
  HOST_FUZZ_TEST \
  STATIC_TEST_LIBRARY \
  HOST_STATIC_TEST_LIBRARY \
  NOTICE_FILE \
  HOST_DALVIK_JAVA_LIBRARY \
  HOST_DALVIK_STATIC_JAVA_LIBRARY \
  base_rules \
  HEADER_LIBRARY \
  HOST_TEST_CONFIG \
  TARGET_TEST_CONFIG

$(foreach s,$(STATS.MODULE_TYPE),$(eval STATS.MODULE_TYPE.$(s) :=))
define record-module-type
$(strip $(if $(LOCAL_RECORDED_MODULE_TYPE),,
  $(if $(filter-out $(SOONG_ANDROID_MK),$(LOCAL_MODULE_MAKEFILE)),
    $(if $(filter $(1),$(STATS.MODULE_TYPE)),
      $(eval LOCAL_RECORDED_MODULE_TYPE := true)
        $(eval STATS.MODULE_TYPE.$(1) += 1),
      $(error Invalid module type: $(1))))))
endef

###########################################################
## Compatibility suite tools
###########################################################

# Return a list of output directories for a given suite and the current LOCAL_MODULE.
# Can be passed a subdirectory to use for the common testcase directory.
define compatibility_suite_dirs
  $(strip \
    $(COMPATIBILITY_TESTCASES_OUT_$(1)) \
    $($(my_prefix)OUT_TESTCASES)/$(LOCAL_MODULE)$(2))
endef

# For each suite:
# 1. Copy the files to the many suite output directories.
# 2. Add all the files to each suite's dependent files list.
# 3. Do the dependency addition to my_all_targets
# Requires for each suite: my_compat_dist_$(suite) to be defined.
define create-suite-dependencies
$(foreach suite, $(LOCAL_COMPATIBILITY_SUITE), \
  $(eval COMPATIBILITY.$(suite).FILES := \
    $(COMPATIBILITY.$(suite).FILES) $(foreach f,$(my_compat_dist_$(suite)),$(call word-colon,2,$(f))))) \
$(eval $(my_all_targets) : $(call copy-many-files, \
  $(sort $(foreach suite,$(LOCAL_COMPATIBILITY_SUITE),$(my_compat_dist_$(suite))))))
endef

###########################################################
## Path Cleaning
###########################################################

# Remove "dir .." combinations (but keep ".. ..")
#
# $(1): The expanded path, where / is converted to ' ' to work with $(word)
define _clean-path-strip-dotdot
$(strip \
  $(if $(word 2,$(1)),
    $(if $(call streq,$(word 2,$(1)),..),
      $(if $(call streq,$(word 1,$(1)),..),
        $(word 1,$(1)) $(call _clean-path-strip-dotdot,$(wordlist 2,$(words $(1)),$(1)))
      ,
        $(call _clean-path-strip-dotdot,$(wordlist 3,$(words $(1)),$(1)))
      )
    ,
      $(word 1,$(1)) $(call _clean-path-strip-dotdot,$(wordlist 2,$(words $(1)),$(1)))
    )
  ,
    $(1)
  )
)
endef

# Remove any leading .. from the path (in case of /..)
#
# Should only be called if the original path started with /
# $(1): The expanded path, where / is converted to ' ' to work with $(word)
define _clean-path-strip-root-dotdots
$(strip $(if $(call streq,$(firstword $(1)),..),
  $(call _clean-path-strip-root-dotdots,$(wordlist 2,$(words $(1)),$(1))),
  $(1)))
endef

# Call _clean-path-strip-dotdot until the path stops changing
# $(1): Non-empty if this path started with a /
# $(2): The expanded path, where / is converted to ' ' to work with $(word)
define _clean-path-expanded
$(strip \
  $(eval _ep := $(call _clean-path-strip-dotdot,$(2)))
  $(if $(1),$(eval _ep := $(call _clean-path-strip-root-dotdots,$(_ep))))
  $(if $(call streq,$(2),$(_ep)),
    $(_ep),
    $(call _clean-path-expanded,$(1),$(_ep))))
endef

# Clean the file path -- remove //, dir/.., extra .
#
# This should be the same semantics as golang's filepath.Clean
#
# $(1): The file path to clean
define clean-path
$(strip \
  $(if $(call streq,$(words $(1)),1),
    $(eval _rooted := $(filter /%,$(1)))
    $(eval _expanded_path := $(filter-out .,$(subst /,$(space),$(1))))
    $(eval _path := $(if $(_rooted),/)$(subst $(space),/,$(call _clean-path-expanded,$(_rooted),$(_expanded_path))))
    $(if $(_path),
      $(_path),
      .
     )
  ,
    $(if $(call streq,$(words $(1)),0),
      .,
      $(error Call clean-path with only one path (without spaces))
    )
  )
)
endef

ifeq ($(TEST_MAKE_clean_path),true)
  define my_test
    $(if $(call streq,$(call clean-path,$(1)),$(2)),,
      $(eval my_failed := true)
      $(warning clean-path test '$(1)': expected '$(2)', got '$(call clean-path,$(1))'))
  endef
  my_failed :=

  # Already clean
  $(call my_test,abc,abc)
  $(call my_test,abc/def,abc/def)
  $(call my_test,a/b/c,a/b/c)
  $(call my_test,.,.)
  $(call my_test,..,..)
  $(call my_test,../..,../..)
  $(call my_test,../../abc,../../abc)
  $(call my_test,/abc,/abc)
  $(call my_test,/,/)

  # Empty is current dir
  $(call my_test,,.)

  # Remove trailing slash
  $(call my_test,abc/,abc)
  $(call my_test,abc/def/,abc/def)
  $(call my_test,a/b/c/,a/b/c)
  $(call my_test,./,.)
  $(call my_test,../,..)
  $(call my_test,../../,../..)
  $(call my_test,/abc/,/abc)

  # Remove doubled slash
  $(call my_test,abc//def//ghi,abc/def/ghi)
  $(call my_test,//abc,/abc)
  $(call my_test,///abc,/abc)
  $(call my_test,//abc//,/abc)
  $(call my_test,abc//,abc)

  # Remove . elements
  $(call my_test,abc/./def,abc/def)
  $(call my_test,/./abc/def,/abc/def)
  $(call my_test,abc/.,abc)

  # Remove .. elements
  $(call my_test,abc/def/ghi/../jkl,abc/def/jkl)
  $(call my_test,abc/def/../ghi/../jkl,abc/jkl)
  $(call my_test,abc/def/..,abc)
  $(call my_test,abc/def/../..,.)
  $(call my_test,/abc/def/../..,/)
  $(call my_test,abc/def/../../..,..)
  $(call my_test,/abc/def/../../..,/)
  $(call my_test,abc/def/../../../ghi/jkl/../../../mno,../../mno)
  $(call my_test,/../abc,/abc)

  # Combinations
  $(call my_test,abc/./../def,def)
  $(call my_test,abc//./../def,def)
  $(call my_test,abc/../../././../def,../../def)

  ifdef my_failed
    $(error failed clean-path test)
  endif
endif

###########################################################
## Given a filepath, returns nonempty if the path cannot be
## validated to be contained in the current directory
## This is, this function checks for '/' and '..'
##
## $(1): path to validate
define try-validate-path-is-subdir
$(strip 
    $(if $(filter /%,$(1)),
        $(1) starts with a slash
    )
    $(if $(filter ../%,$(call clean-path,$(1))),
        $(1) escapes its parent using '..'
    )
    $(if $(strip $(1)),
    ,
        '$(1)' is empty
    )
)
endef

define validate-path-is-subdir
$(if $(call try-validate-path-is-subdir,$(1)),
  $(call pretty-error, Illegal path: $(call try-validate-path-is-subdir,$(1)))
)
endef

###########################################################
## Given a space-delimited list of filepaths, returns
## nonempty if any cannot be validated to be contained in
## the current directory
##
## $(1): path list to validate
define try-validate-paths-are-subdirs
$(strip \
  $(foreach my_path,$(1),\
    $(call try-validate-path-is-subdir,$(my_path))\
  )
)
endef

define validate-paths-are-subdirs
$(if $(call try-validate-paths-are-subdirs,$(1)),
    $(call pretty-error,Illegal paths:\'$(call try-validate-paths-are-subdirs,$(1))\')
)
endef

###########################################################
## Tests of try-validate-path-is-subdir
##     and  try-validate-paths-are-subdirs
define test-validate-paths-are-subdirs
$(eval my_error := $(call try-validate-path-is-subdir,/tmp)) \
$(if $(call streq,$(my_error),/tmp starts with a slash),
,
  $(error incorrect error message for path /tmp. Got '$(my_error)')
) \
$(eval my_error := $(call try-validate-path-is-subdir,../sibling)) \
$(if $(call streq,$(my_error),../sibling escapes its parent using '..'),
,
  $(error incorrect error message for path ../sibling. Got '$(my_error)')
) \
$(eval my_error := $(call try-validate-path-is-subdir,child/../../sibling)) \
$(if $(call streq,$(my_error),child/../../sibling escapes its parent using '..'),
,
  $(error incorrect error message for path child/../../sibling. Got '$(my_error)')
) \
$(eval my_error := $(call try-validate-path-is-subdir,)) \
$(if $(call streq,$(my_error),'' is empty),
,
  $(error incorrect error message for empty path ''. Got '$(my_error)')
) \
$(eval my_error := $(call try-validate-path-is-subdir,subdir/subsubdir)) \
$(if $(call streq,$(my_error),),
,
  $(error rejected valid path 'subdir/subsubdir'. Got '$(my_error)')
)

$(eval my_error := $(call try-validate-paths-are-subdirs,a/b /c/d e/f))
$(if $(call streq,$(my_error),/c/d starts with a slash),
,
  $(error incorrect error message for path list 'a/b /c/d e/f'. Got '$(my_error)')
)
$(eval my_error := $(call try-validate-paths-are-subdirs,a/b c/d))
$(if $(call streq,$(my_error),),
,
  $(error rejected valid path list 'a/b c/d'. Got '$(my_error)')
)
endef
# run test
$(strip $(call test-validate-paths-are-subdirs))

###########################################################
## Validate jacoco class filters and convert them to
## file arguments
## Jacoco class filters are comma-separated lists of class
## files (android.app.Application), and may have '*' as the
## last character to match all classes in a package
## including subpackages.
define jacoco-class-filter-to-file-args
$(strip $(call jacoco-validate-file-args,\
  $(subst $(comma),$(space),\
    $(subst .,/,\
      $(strip $(1))))))
endef

define jacoco-validate-file-args
$(strip $(1)\
  $(call validate-paths-are-subdirs,$(1))
  $(foreach arg,$(1),\
    $(if $(findstring ?,$(arg)),$(call pretty-error,\
      '?' filters are not supported in LOCAL_JACK_COVERAGE_INCLUDE_FILTER or LOCAL_JACK_COVERAGE_EXCLUDE_FILTER))\
    $(if $(findstring *,$(patsubst %*,%,$(arg))),$(call pretty-error,\
      '*' is only supported at the end of a filter in LOCAL_JACK_COVERAGE_INCLUDE_FILTER or LOCAL_JACK_COVERAGE_EXCLUDE_FILTER))\
  ))
endef

###########################################################
## Other includes
###########################################################

# -----------------------------------------------------------------
# Rules and functions to help copy important files to DIST_DIR
# when requested.
include $(BUILD_SYSTEM)/distdir.mk

# Include any vendor specific definitions.mk file
-include $(TOPDIR)vendor/*/build/core/definitions.mk
-include $(TOPDIR)device/*/build/core/definitions.mk
-include $(TOPDIR)product/*/build/core/definitions.mk

# broken:
#	$(foreach file,$^,$(if $(findstring,.a,$(suffix $file)),-l$(file),$(file)))

###########################################################
## Misc notes
###########################################################

#DEPDIR = .deps
#df = $(DEPDIR)/$(*F)

#SRCS = foo.c bar.c ...

#%.o : %.c
#	@$(MAKEDEPEND); \
#	  cp $(df).d $(df).P; \
#	  sed -e 's/#.*//' -e 's/^[^:]*: *//' -e 's/ *\\$$//' \
#	      -e '/^$$/ d' -e 's/$$/ :/' < $(df).d >> $(df).P; \
#	  rm -f $(df).d
#	$(COMPILE.c) -o $@ $<

#-include $(SRCS:%.c=$(DEPDIR)/%.P)


#%.o : %.c
#	$(COMPILE.c) -MD -o $@ $<
#	@cp $*.d $*.P; \
#	  sed -e 's/#.*//' -e 's/^[^:]*: *//' -e 's/ *\\$$//' \
#	      -e '/^$$/ d' -e 's/$$/ :/' < $*.d >> $*.P; \
#	  rm -f $*.d


###########################################################
# Append the information to generate a RRO package for the
# source module.
#
#  $(1): Source module name.
#  $(2): Whether $(3) is a manifest package name or not.
#  $(3): Manifest package name if $(2) is true.
#        Otherwise, android manifest file path of the
#        source module.
#  $(4): Whether LOCAL_EXPORT_PACKAGE_RESOURCES is set or
#        not for the source module.
#  $(5): Resource overlay list.
###########################################################
define append_enforce_rro_sources
  $(eval ENFORCE_RRO_SOURCES += \
      $(strip $(1))||$(strip $(2))||$(strip $(3))||$(strip $(4))||$(call normalize-path-list, $(strip $(5))))
endef

###########################################################
# Generate all RRO packages for source modules stored in
# ENFORCE_RRO_SOURCES
###########################################################
define generate_all_enforce_rro_packages
$(foreach source,$(ENFORCE_RRO_SOURCES), \
  $(eval _o := $(subst ||,$(space),$(source))) \
  $(eval enforce_rro_source_module := $(word 1,$(_o))) \
  $(eval enforce_rro_source_is_manifest_package_name := $(word 2,$(_o))) \
  $(eval enforce_rro_source_manifest_package_info := $(word 3,$(_o))) \
  $(eval enforce_rro_use_res_lib := $(word 4,$(_o))) \
  $(eval enforce_rro_source_overlays := $(subst :, ,$(word 5,$(_o)))) \
  $(eval enforce_rro_module := $(enforce_rro_source_module)__auto_generated_rro) \
  $(eval include $(BUILD_SYSTEM)/generate_enforce_rro.mk) \
  $(eval ALL_MODULES.$(enforce_rro_source_module).REQUIRED += $(enforce_rro_module)) \
)
endef

###########################################################
## Find system_$(VER) in LOCAL_SDK_VERSION
##
## $(1): LOCAL_SDK_VERSION
###########################################################
define has-system-sdk-version
$(filter system_%,$(1))
endef

###########################################################
## Get numerical version in LOCAL_SDK_VERSION
##
## $(1): LOCAL_SDK_VERSION
###########################################################
define get-numeric-sdk-version
$(filter-out current,\
  $(if $(call has-system-sdk-version,$(1)),$(patsubst system_%,%,$(1)),$(1)))
endef

# Convert to lower case without requiring a shell, which isn't cacheable.
to-lower=$(subst A,a,$(subst B,b,$(subst C,c,$(subst D,d,$(subst E,e,$(subst F,f,$(subst G,g,$(subst H,h,$(subst I,i,$(subst J,j,$(subst K,k,$(subst L,l,$(subst M,m,$(subst N,n,$(subst O,o,$(subst P,p,$(subst Q,q,$(subst R,r,$(subst S,s,$(subst T,t,$(subst U,u,$(subst V,v,$(subst W,w,$(subst X,x,$(subst Y,y,$(subst Z,z,$1))))))))))))))))))))))))))

# Convert to upper case without requiring a shell, which isn't cacheable.
to-upper=$(subst a,A,$(subst b,B,$(subst c,C,$(subst d,D,$(subst e,E,$(subst f,F,$(subst g,G,$(subst h,H,$(subst i,I,$(subst j,J,$(subst k,K,$(subst l,L,$(subst m,M,$(subst n,N,$(subst o,O,$(subst p,P,$(subst q,Q,$(subst r,R,$(subst s,S,$(subst t,T,$(subst u,U,$(subst v,V,$(subst w,W,$(subst x,X,$(subst y,Y,$(subst z,Z,$1))))))))))))))))))))))))))

# Sanity-check to-lower and to-upper
lower := abcdefghijklmnopqrstuvwxyz-_
upper := ABCDEFGHIJKLMNOPQRSTUVWXYZ-_

ifneq ($(lower),$(call to-lower,$(upper)))
  $(error to-lower sanity check failure)
endif

ifneq ($(upper),$(call to-upper,$(lower)))
  $(error to-upper sanity check failure)
endif

lower :=
upper :=