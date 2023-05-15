
.PHONY: clean FORCE

CXX       ?= cpp
PKGCONFIG ?= pkg-config
SED       ?= sed
RM        ?= rm -f

NIX_DEV_PREFIX ?=                                               \
	/nix/store/fx6i2p6sn88gymik9f6qln86s978vwkr-nix-2.13.3-dev

BOOST_PREFIX ?=                                                   \
	/nix/store/zhknm5hxij5gprm3xrd41r6lipvjkfc9-boost-1.79.0-dev

NLOHMANN_JSON_PREFIX ?=                                               \
	/nix/store/y0sajf4ns4drdgw531q450kb0xvhvdqw-nlohmann_json-3.11.2

BOEHM_GC_PREFIX = /nix/store/v6qmar0d24a5dkswq0rwajw95irvzaim-boehm-gc-8.2.2-dev

PKG_CONFIG_PATH = $(NIX_DEV_PREFIX)/lib/pkgconfig:$(BOEHM_GC_PREFIX)/lib/pkgconfig

CPPFLAGS =                                         \
  -I$(NIX_DEV_PREFIX)/include                      \
  -I$(BOOST_PREFIX)/include                        \
  -I$(NLOHMANN_JSON_PREFIX)/include                \
  -include $(NIX_DEV_PREFIX)/include/nix/config.h  \
  $(shell PKG_CONFIG_PATH=$(PKG_CONFIG_PATH) $(PKGCONFIG) --cflags nix-store nix-main nix-expr)

CXXFLAGS = -std=c++17

LDFLAGS =  \
	$(shell PKG_CONFIG_PATH=$(PKG_CONFIG_PATH) $(PKGCONFIG) --libs nix-store nix-main nix-expr)


resolve: main.cc
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) $(LDFLAGS) "$<" -o "$@"

clean: FORCE
	$(RM) resolve
