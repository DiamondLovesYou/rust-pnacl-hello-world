ifneq ($(MAKECMDGOALS),clean)
ifeq ($(SYSROOT),)
$(error I need the sysroot to your Rust build)
endif
endif

RUSTC ?= $(shell readlink -f $(SYSROOT)/bin/rustc)
NACL_SDK  ?= $(shell readlink -f ~/workspace/tools/nacl-sdk/pepper_canary)

ifneq ($(MAKECMDGOALS),clean)
ifeq  ($(NACL_SDK),)
$(error I need the directory to your Pepper SDK!)
endif
endif

USE_DEBUG ?= 0
RUSTFLAGS += -C cross-path=$(NACL_SDK) -C nacl-flavor=pnacl --target=le32-unknown-nacl -L $(RUST_HTTP) --sysroot=$(shell readlink -f $(SYSROOT))
TOOLCHAIN ?= $(NACL_SDK)/toolchain/linux_pnacl

# deps
RUST_HTTP    ?= $(shell readlink -f deps/http)
RUST_OPENSSL ?= $(shell readlink -f deps/openssl)
RUST_PPAPI   ?= $(shell readlink -f deps/ppapi)

ifeq ($(USE_DEBUG),0)
RUSTFLAGS += -O --cfg ndebug -C stable-pexe
INDEX_FILE := index.html
else
RUSTFLAGS += --debuginfo=2 -Z no-opt
INDEX_FILE := index.debug.html
endif

rwildcard = $(foreach d,$(wildcard $1*),$(call rwildcard,$d/,$2) $(filter $(subst *,%,$2),$d))

.DEFAULT_GOAL := all

all: build/main.pexe serve

clean:
	touch Makefile


PORT ?= 5103
.PHONY += serve
serve: build/main.pexe
	$(NACL_SDK)/tools/http.py --serve-dir . --port=$(PORT) &
	www-browser "http://localhost:$(PORT)/$(INDEX_FILE)"

build/main.pexe: main.rs Makefile deps/ppapi.stamp
	$(RUSTC) $(RUSTFLAGS) -o $@ $< -L $(RUST_PPAPI)/build -L $(RUST_HTTP)/build -L $(RUST_OPENSSL)/build -L $(TOOLCHAIN)/sdk/lib

build/main.nexe: build/main.pexe
	$(TOOLCHAIN)/bin/pnacl-translate --allow-llvm-bitcode -arch x86_64 -o $@ $<

# deps

$(RUST_HTTP)/Makefile: $(RUST_HTTP)/configure $(RUST_HTTP)/Makefile.in Makefile
	cd $(RUST_HTTP); \
	./configure

deps/http.stamp: $(RUST_HTTP)/Makefile deps/openssl.stamp \
		 $(call rwildcard,$(RUST_HTTP),*rs) \
		 $(RUSTC)
	make -C $(RUST_HTTP) clean
	RUSTC="$(RUSTC)" RUSTFLAGS="$(RUSTFLAGS)" make -C $(RUST_HTTP)
	touch $@

$(RUST_OPENSSL)/Makefile: $(RUST_OPENSSL)/configure $(RUST_OPENSSL)/Makefile.in Makefile
	cd $(RUST_OPENSSL); \
	./configure

deps/openssl.stamp: $(RUST_OPENSSL)/Makefile \
		    $(call rwildcard,$(RUST_OPENSSL),*rs) \
		    $(RUSTC)
	RUSTC="$(RUSTC)" RUSTFLAGS="$(filter-out -O,$(RUSTFLAGS))" make -C $(RUST_OPENSSL)
	touch $@

deps/ppapi.stamp: deps/http.stamp \
		  $(RUST_PPAPI)/Makefile \
		  $(call rwildcard,$(RUST_PPAPI),*rs) \
		  $(RUSTC)
	make -C $(RUST_PPAPI)                  \
		RUSTC="$(RUSTC)"               \
		SYSROOT="$(SYSROOT)"           \
		NACL_SDK="$(NACL_SDK)"         \
		RUST_HTTP="$(RUST_HTTP)"       \
		RUST_OPENSSL="$(RUST_OPENSSL)"
	touch $@
