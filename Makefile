ifneq ($(MAKECMDGOALS),clean)
ifeq ($(SYSROOT),)
$(error I need the sysroot to your Rust build)
endif
endif

SYSROOT := $(abspath $(SYSROOT))

RUSTC ?= $(shell readlink -f $(SYSROOT)/bin/rustc)
RUST_PNACL_TRANS ?= $(shell readlink -f $(SYSROOT)/bin/rust-pnacl-trans)

NACL_SDK  ?= $(shell readlink -f $(NACL_SDK_ROOT))

ifneq ($(MAKECMDGOALS),clean)
ifeq  ($(NACL_SDK),)
$(error I need the directory to your Pepper SDK! Use NACL_SDK_ROOT.)
endif
endif

export LD_LIBRARY_PATH := $(SYSROOT)/lib:$(LD_LIBRARY_PATH)

# deps
RUST_HTTP    ?= $(shell readlink -f deps/http)
RUST_OPENSSL ?= $(shell readlink -f deps/openssl)
RUST_PPAPI   ?= $(shell readlink -f deps/ppapi)

USE_DEBUG ?= 0
RUSTFLAGS += -C cross-path=$(NACL_SDK) --target=le32-unknown-nacl --sysroot=$(shell readlink -f $(SYSROOT))
TOOLCHAIN ?= $(NACL_SDK)/toolchain/linux_pnacl

BUILD_DIR ?= $(abspath build)
INDEX_FILE ?= index.html

ifeq ($(USE_DEBUG),0)

RUSTFLAGS += -O --cfg ndebug

MAIN_TARGET := $(BUILD_DIR)/pnacl-hello-world.pexe

else

RUSTFLAGS += --debuginfo=2 -Z no-opt

MAIN_TARGET := $(BUILD_DIR)/pnacl-hello-world.nexe

endif

PORT ?= 5103

BOZOHTTPD_PID := http_server.port-$(PORT).pid

rwildcard = $(foreach d,$(wildcard $1*),$(call rwildcard,$d/,$2) $(filter $(subst *,%,$2),$d))

.DEFAULT_GOAL := all

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

all: $(BUILD_DIR)/pnacl-hello-world.pexe $(BUILD_DIR)/pnacl-hello-world.nexe

clean:
	$(MAKE) -C $(RUST_PPAPI) clean
	touch Makefile

$(BOZOHTTPD_PID):
	bozohttpd -b -I $(PORT) -P $@ ./.; sleep 1s

.PHONY += serve
serve: $(MAIN_TARGET) | $(BOZOHTTPD_PID)
	google-chrome "http://localhost:$(PORT)/$(INDEX_FILE)"

$(BUILD_DIR)/pnacl-hello-world.pexe: $(BUILD_DIR)/pnacl-hello-world.stamp
	$(TOOLCHAIN)/bin/pnacl-compress $@

$(BUILD_DIR)/pnacl-hello-world.stamp: main.rs $(RUSTC) Makefile deps/ppapi.stamp | $(BUILD_DIR)
	$(RUSTC) $(RUSTFLAGS) --out-dir $(BUILD_DIR) $< -L $(BUILD_DIR) -L $(TOOLCHAIN)/sdk/lib --emit=link,bc -C stable-pexe

$(BUILD_DIR)/pnacl-hello-world.nexe: $(BUILD_DIR)/pnacl-hello-world.pexe $(RUST_PNACL_TRANS)
	$(RUST_PNACL_TRANS) -o $@ $(patsubst %.pexe,%.bc,$<) --cross-path=$(NACL_SDK)

# deps

deps/ppapi.stamp: $(RUST_PPAPI)/Makefile \
		  $(call rwildcard,$(RUST_PPAPI),*rs) \
		  $(call rwildcard,$(RUST_HTTP),*rs) \
		  $(call rwildcard,$(RUST_OPENSSL),*rs) \
		  $(RUSTC) | $(BUILD_DIR)
	$(MAKE) -C $(RUST_PPAPI)               \
		RUSTC="$(RUSTC)"               \
		SYSROOT="$(SYSROOT)"           \
		NACL_SDK="$(NACL_SDK)"         \
		RUST_HTTP="$(RUST_HTTP)"       \
		RUST_OPENSSL="$(RUST_OPENSSL)" \
		BUILD_DIR="$(BUILD_DIR)"       \
		USE_DEBUG=$(USE_DEBUG)
