ifneq ($(MAKECMDGOALS),clean)
ifeq ($(SYSROOT),)
$(error I need the sysroot to your Rust build)
endif
endif

SYSROOT := $(abspath $(SYSROOT))

RUSTC ?= $(shell readlink -f $(SYSROOT)/bin/rustc)
RUST_PNACL_TRANS ?= $(shell readlink -f $(SYSROOT)/bin/rust-pnacl-trans)

NACL_SDK  ?= $(shell readlink -f ~/workspace/tools/nacl-sdk/pepper_canary)

ifneq ($(MAKECMDGOALS),clean)
ifeq  ($(NACL_SDK),)
$(error I need the directory to your Pepper SDK!)
endif
endif

# deps
RUST_HTTP    ?= $(shell readlink -f deps/http)
RUST_OPENSSL ?= $(shell readlink -f deps/openssl)
RUST_PPAPI   ?= $(shell readlink -f deps/ppapi)

USE_DEBUG ?= 0
RUSTFLAGS += -C cross-path=$(NACL_SDK) -C nacl-flavor=pnacl --target=le32-unknown-nacl -L $(RUST_HTTP)/build --sysroot=$(shell readlink -f $(SYSROOT))
TOOLCHAIN ?= $(NACL_SDK)/toolchain/linux_pnacl

BUILD_DIR ?= $(abspath build)

ifeq ($(USE_DEBUG),0)

RUSTFLAGS += -O --cfg ndebug
INDEX_FILE := index.html

MAIN_TARGET := $(BUILD_DIR)/main.pexe

else

RUSTFLAGS += --debuginfo=2 -Z no-opt
INDEX_FILE := index.debug.html

MAIN_TARGET := $(BUILD_DIR)/main.nexe

endif

PORT ?= 5103

rwildcard = $(foreach d,$(wildcard $1*),$(call rwildcard,$d/,$2) $(filter $(subst *,%,$2),$d))

.DEFAULT_GOAL := all

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

all: $(BUILD_DIR)/main.pexe $(BUILD_DIR)/main.nexe

clean:
	$(MAKE) -C $(RUST_PPAPI) clean
	touch Makefile

http_server.pid:
	bozohttpd -b -I $(PORT) -P $@ ./.; sleep 1s

.PHONY += serve
serve: $(MAIN_TARGET) | http_server.pid
	google-chrome "http://localhost:$(PORT)/$(INDEX_FILE)"

$(BUILD_DIR)/main: main.rs $(RUSTC) Makefile deps/ppapi.stamp | $(BUILD_DIR)
	$(RUSTC) $(RUSTFLAGS) --out-dir $(BUILD_DIR) $< -L $(RUST_PPAPI)/build -L $(RUST_HTTP)/target \
		-L $(RUST_OPENSSL)/target -L $(TOOLCHAIN)/sdk/lib --emit=link,bc -C stable-pexe

$(BUILD_DIR)/main.pexe: $(BUILD_DIR)/main
	cp $< $@

$(BUILD_DIR)/main.nexe: $(BUILD_DIR)/main $(RUST_PNACL_TRANS)
	$(RUST_PNACL_TRANS) -o $@ $<.bc --cross-path=$(NACL_SDK)

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
		BUILD_DIR="$(BUILD_DIR)"
