PROJECT := palletgeist
SOURCE_DIR := src
BUILD_DIR := build

ODIN ?= odin
CMAKE ?= cmake
EMCMAKE ?= emcmake
EMCC ?= emcc
CURL ?= curl
PYTHON ?= python3
ODIN_FLAGS ?=
WEB_ODIN_FLAGS ?= -o:speed
WEB_EMCC_FLAGS ?= -O2

RULES_SOURCE_DIR := bomb-box-rules-c
RULES_BUILD_DIR := $(BUILD_DIR)/game-rules
RULES_LIBRARY := $(RULES_BUILD_DIR)/libgame_rules_state_c.a
WEB_BUILD_DIR := $(BUILD_DIR)/web
WEB_RULES_BUILD_DIR := $(BUILD_DIR)/game-rules-wasm
WEB_RULES_LIBRARY := $(WEB_RULES_BUILD_DIR)/libgame_rules_state_c.a
WEB_DEPS_DIR := $(BUILD_DIR)/deps
WEB_RAYLIB_CACHE := $(WEB_DEPS_DIR)/libraylib.web.a
WEB_RAYGUI_CACHE := $(WEB_DEPS_DIR)/libraygui.a
WEB_ODIN_OBJECT := $(WEB_BUILD_DIR)/palletgeist.obj
ODIN_ROOT := $(shell $(ODIN) root)
SYSTEM_RAYLIB_WEB := $(firstword $(wildcard \
	$(ODIN_ROOT)/vendor/raylib/wasm/libraylib.web.a \
	$(ODIN_ROOT)/vendor/raylib/wasm/libraylib.a))
SYSTEM_RAYGUI_WEB := $(firstword $(wildcard \
	$(ODIN_ROOT)/vendor/raylib/wasm/libraygui.a))
RAYLIB_WEB_LIBRARY ?= $(if $(SYSTEM_RAYLIB_WEB),$(SYSTEM_RAYLIB_WEB),$(WEB_RAYLIB_CACHE))
RAYGUI_WEB_LIBRARY ?= $(if $(SYSTEM_RAYGUI_WEB),$(SYSTEM_RAYGUI_WEB),$(WEB_RAYGUI_CACHE))

# This revision matches raylib 6.0 and Odin's current vendor bindings. Homebrew
# omits Odin's Git-LFS WebAssembly archives, so cache the official one locally.
RAYLIB_WEB_REV ?= 819fdc7a8
RAYLIB_WEB_SHA256 ?= e1fc3ce2afd4bf1ac08420dd9350749512d9b6e34bc05a78c9ea9d17b5f440b3
RAYLIB_WEB_URL ?= https://media.githubusercontent.com/media/odin-lang/Odin/$(RAYLIB_WEB_REV)/vendor/raylib/wasm/libraylib.web.a
RAYGUI_WEB_SHA256 ?= 59df4e818723dcc381980b4bb0181b4009bdeddc9614a09c158c6d11b66308e3
RAYGUI_WEB_URL ?= https://raw.githubusercontent.com/odin-lang/Odin/$(RAYLIB_WEB_REV)/vendor/raylib/wasm/libraygui.a

.PHONY: all build run check rules web web-rules web-serve web-package clean

all: build

build: rules
	@mkdir -p $(BUILD_DIR)
	$(ODIN) build $(SOURCE_DIR) -out:$(BUILD_DIR)/$(PROJECT) -debug $(ODIN_FLAGS)

run: build
	./$(BUILD_DIR)/$(PROJECT)

check: rules
	$(ODIN) check $(SOURCE_DIR) $(ODIN_FLAGS)

rules:
	$(CMAKE) -S $(RULES_SOURCE_DIR) -B $(RULES_BUILD_DIR) \
		-DBUILD_TESTING=OFF \
		-DGAME_RULES_C_BUILD_EXAMPLES=OFF \
		-DCMAKE_BUILD_TYPE=Debug
	$(CMAKE) --build $(RULES_BUILD_DIR) --target game_rules_state_c

web-rules:
	$(EMCMAKE) $(CMAKE) -S $(RULES_SOURCE_DIR) -B $(WEB_RULES_BUILD_DIR) \
		-DBUILD_TESTING=OFF \
		-DGAME_RULES_C_BUILD_EXAMPLES=OFF \
		-DCMAKE_BUILD_TYPE=Release
	$(CMAKE) --build $(WEB_RULES_BUILD_DIR) --target game_rules_state_c

$(WEB_RAYLIB_CACHE):
	@mkdir -p $(WEB_DEPS_DIR)
	$(CURL) -fsSL $(RAYLIB_WEB_URL) -o $@.tmp
	@echo "$(RAYLIB_WEB_SHA256)  $@.tmp" | shasum -a 256 -c -
	@mv $@.tmp $@

$(WEB_RAYGUI_CACHE):
	@mkdir -p $(WEB_DEPS_DIR)
	$(CURL) -fsSL $(RAYGUI_WEB_URL) -o $@.tmp
	@echo "$(RAYGUI_WEB_SHA256)  $@.tmp" | shasum -a 256 -c -
	@mv $@.tmp $@

web: web-rules $(RAYLIB_WEB_LIBRARY) $(RAYGUI_WEB_LIBRARY)
	@mkdir -p $(WEB_BUILD_DIR)
	$(ODIN) build $(SOURCE_DIR) \
		-target:js_wasm32 \
		-build-mode:obj \
		-define:RAYLIB_WASM_LIB=env.o \
		-define:RAYGUI_WASM_LIB=env.o \
		-out:$(WEB_ODIN_OBJECT) \
		$(WEB_ODIN_FLAGS)
	@cp $(ODIN_ROOT)/core/sys/wasm/js/odin.js $(WEB_BUILD_DIR)/odin.js
	$(EMCC) -o $(WEB_BUILD_DIR)/index.html \
		$(WEB_ODIN_OBJECT) \
		$(WEB_RULES_LIBRARY) \
		$(RAYLIB_WEB_LIBRARY) \
		$(RAYGUI_WEB_LIBRARY) \
		$(WEB_EMCC_FLAGS) \
		-sUSE_GLFW=3 \
		-sWASM_BIGINT=1 \
		-sALLOW_MEMORY_GROWTH=1 \
		-sINITIAL_MEMORY=67108864 \
		-sSTACK_SIZE=1048576 \
		-sASSERTIONS=1 \
		-sWARN_ON_UNDEFINED_SYMBOLS=0 \
		--shell-file web/index_template.html \
		--preload-file assets@/assets
	@rm -f $(WEB_ODIN_OBJECT)
	@echo "Web build created in $(WEB_BUILD_DIR)"

web-serve: web
	$(PYTHON) -m http.server 8000 --directory $(WEB_BUILD_DIR)

web-package: web
	cd $(WEB_BUILD_DIR) && zip -q -FS ../$(PROJECT)-web.zip \
		index.html index.js index.wasm index.data odin.js
	@echo "itch.io upload created at $(BUILD_DIR)/$(PROJECT)-web.zip"

clean:
	rm -rf $(BUILD_DIR)
