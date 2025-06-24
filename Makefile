HEAP_SIZE  = 8388208
STACK_SIZE = 61800

PRODUCT = Roxy\ Engine\ Test\ Suite.pdx

# Locate the SDK
SDK = ${PLAYDATE_SDK_PATH}
ifeq ($(SDK),)
SDK = $(shell egrep '^\s*SDKRoot' ~/.Playdate/config | head -n 1 | cut -c9-)
endif
ifeq ($(SDK),)
$(error SDK path not found; set ENV value PLAYDATE_SDK_PATH)
endif

# List source lookup paths
VPATH +=  \
          source/libraries/roxy \
          source/libraries/roxy/utilities \
          source/libraries/roxy/core/sequences

# List C source files here
SRC =   \
        source/libraries/roxy/roxy.c \
        source/libraries/roxy/utilities/roxy_math.c \
        source/libraries/roxy/utilities/roxy_ease.c \
        source/libraries/roxy/core/sequences/roxy_sequence.c

include $(SDK)/C_API/buildsupport/common.mk
