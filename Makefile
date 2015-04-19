SYSROOT ?= /usr/local
SYSROOT := $(abspath $(SYSROOT))

RUSTC ?= $(shell readlink -f $(SYSROOT)/bin/rustc)
CARGO ?= $(shell which cargo)
RUST_PNACL_TRANS ?= $(shell readlink -f $(SYSROOT)/bin/rust_pnacl_trans)

NACL_SDK_ROOT  ?= $(shell readlink -f $(NACL_SDK_ROOT))

ifneq ($(MAKECMDGOALS),clean)
ifeq  ($(NACL_SDK_ROOT),)
$(error I need the directory to your Pepper SDK! Use NACL_SDK_ROOT.)
endif
endif

export NACL_SDK_ROOT

CC_le32_unknown_nacl  :=$(shell $(NACL_SDK_ROOT)/tools/nacl_config.py -t pnacl --tool cc)
CXX_le32_unknown_nacl :=$(shell $(NACL_SDK_ROOT)/tools/nacl_config.py -t pnacl --tool cxx)
AR_le32_unknown_nacl  :=$(shell $(NACL_SDK_ROOT)/tools/nacl_config.py -t pnacl --tool ar)
export CC
export CXX
export AR

VERBOSE ?= 0
ifeq ($(VERBOSE),1)
CARGO_BUILD_FLAGS += --verbose
endif

export LD_LIBRARY_PATH := $(SYSROOT)/lib:$(LD_LIBRARY_PATH)

USE_DEBUG ?= 0
TOOLCHAIN ?= $(NACL_SDK_ROOT)/toolchain/linux_pnacl

TARGET = le32-unknown-nacl

BUILD_DIR := $(abspath target)/$(TARGET)
INDEX_FILE ?= index.html

ifeq ($(USE_DEBUG),0)

CARGO_BUILD_FLAGS += --release

MAIN_SOURCE := $(BUILD_DIR)/release/pnacl-hello-world.pexe
MAIN_TARGET := $(BUILD_DIR)/release/pnacl-hello-world.stamp

$(MAIN_TARGET): $(MAIN_SOURCE)
	$(TOOLCHAIN)/bin/pnacl-compress $<
	touch $@

else

RUSTFLAGS += --debuginfo=2

MAIN_SOURCE := $(BUILD_DIR)/debug/pnacl_hello_world.debug.pexe
MAIN_TARGET := $(BUILD_DIR)/debug/pnacl-hello-world.nexe

$(MAIN_TARGET): $(MAIN_SOURCE) $(RUST_PNACL_TRANS)
	$(RUST_PNACL_TRANS) -o $@ $< --cross-path=$(NACL_SDK_ROOT)
endif

PORT ?= 5103

BOZOHTTPD_PID := http_server.port-$(PORT).pid

rwildcard = $(foreach d,$(wildcard $1*),$(call rwildcard,$d/,$2) $(filter $(subst *,%,$2),$d))

.DEFAULT_GOAL := all

all: $(MAIN_TARGET)

clean:
	$(CARGO) clean
	touch Makefile

$(BOZOHTTPD_PID):
	bozohttpd -b -I $(PORT) -P $@ ./.; sleep 1s

.PHONY += serve
serve: $(MAIN_TARGET) | $(BOZOHTTPD_PID)
	google-chrome "http://localhost:$(PORT)/$(INDEX_FILE)"

$(MAIN_SOURCE): src/main.rs $(CARGO) Makefile
	$(CARGO) build --target $(TARGET) $(CARGO_BUILD_FLAGS)
