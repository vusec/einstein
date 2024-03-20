# Tool-specific vars
MY_TOOL := einstein
MY_OBJS := einstein_main einstein_callback einstein_debug einstein_dftrop einstein_syscalls einstein_syscalls_unimpl einstein_syscalls_internal einstein_utils einstein_rewrite

################################################################
## libdft tool-generic vars
################################################################

# Check env vars
ifndef PIN_ROOT
$(error PIN_ROOT is not set)
endif
ifndef LIBDFT
$(error LIBDFT is not set)
endif

# Pin boilerplate
CONFIG_ROOT := $(PIN_ROOT)/source/tools/Config
include $(CONFIG_ROOT)/makefile.config
include makefile.rules
include $(TOOLS_ROOT)/Config/makefile.default.rules

# Use libdft
TOOL_CXXFLAGS += -I$(LIBDFT)/src -L$(LIBDFT)/src/obj-$(PIN_ARCH) ${CPPFLAGS}
TOOL_LDFLAGS  += -L$(LIBDFT)/src/obj-$(PIN_ARCH)
TOOL_LIBS     += -ldft

