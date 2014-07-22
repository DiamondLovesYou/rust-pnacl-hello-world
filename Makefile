ifneq ($(MAKECMDGOALS),clean)
ifeq ($(SYSROOT),)
$(error I need the sysroot to your Rust build)
endif
endif

SYSROOT := $(abspath $(SYSROOT))

RUSTC ?= $(shell readlink -f $(SYSROOT)/bin/rustc)
RUST_PNACL_TRANS ?= $(abspath $(SYSROOT)/bin/rust-pnacl-trans)

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

ifeq ($(USE_DEBUG),0)
RUSTFLAGS += -O --cfg ndebug -C stable-pexe
INDEX_FILE := index.html
build/main = build/main.pexe
else
RUSTFLAGS += --debuginfo=2 -Z no-opt
INDEX_FILE := index.debug.html
build/main = build/main.nexe
endif

rwildcard = $(foreach d,$(wildcard $1*),$(call rwildcard,$d/,$2) $(filter $(subst *,%,$2),$d))

.DEFAULT_GOAL := all

BUILD_DIR ?= $(abspath build)

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

all: build/main.pexe serve

clean:
	$(MAKE) -C $(RUST_PPAPI) clean
	touch Makefile


PORT ?= 5103
.PHONY += serve
serve: build/main
	$(NACL_SDK)/tools/httpd.py --serve-dir . --port=$(PORT) --no-dir-check &
	google-chrome "http://localhost:$(PORT)/$(INDEX_FILE)"

build/main.pexe: main.rs $(RUSTC) Makefile deps/ppapi.stamp | $(BUILD_DIR)
	$(RUSTC) $(RUSTFLAGS) -o $(abspath $@) $< -L $(RUST_PPAPI)/build -L $(RUST_HTTP)/target -L $(RUST_OPENSSL)/target -L $(TOOLCHAIN)/sdk/lib

build/main.nexe: $(RUST_PNACL_TRANS) build/main.pexe
	$(RUST_PNACL_TRANS) -o $(abspath $@) $< --cross-path=$(NACL_SDK)

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
