PROJECT := palletgeist
SOURCE_DIR := src
BUILD_DIR := build
ASSET_DIR := assets
BUILD_ASSET_DIR := $(BUILD_DIR)/assets
RULES_SOURCE_DIR := bomb-box-rules-c
RULES_BUILD_DIR := $(BUILD_DIR)/game-rules
RULES_LIBRARY := $(RULES_BUILD_DIR)/libgame_rules_state_c.a

ifeq ($(OS),Windows_NT)
PROJECT_BINARY := $(BUILD_DIR)/$(PROJECT).exe
CREATE_BUILD_DIR = if not exist "$(BUILD_DIR)" mkdir "$(BUILD_DIR)"
COPY_ASSETS = xcopy /E /I /Y "$(ASSET_DIR)" "$(BUILD_ASSET_DIR)" >NUL
RUN_PROJECT = "$(PROJECT_BINARY)"
CLEAN_BUILD_DIR = if exist "$(BUILD_DIR)" rmdir /S /Q "$(BUILD_DIR)"
PLATFORM_ODIN_FLAGS := -subsystem:windows
else
PROJECT_BINARY := $(BUILD_DIR)/$(PROJECT)
CREATE_BUILD_DIR = mkdir -p "$(BUILD_DIR)"
COPY_ASSETS = rm -rf "$(BUILD_ASSET_DIR)" && cp -R "$(ASSET_DIR)" "$(BUILD_ASSET_DIR)"
RUN_PROJECT = ./$(PROJECT_BINARY)
CLEAN_BUILD_DIR = rm -rf "$(BUILD_DIR)"
PLATFORM_ODIN_FLAGS :=
endif

ODIN ?= odin
CMAKE ?= cmake
ODIN_FLAGS ?=

.PHONY: all build run check rules clean

all: build

build: rules
	@$(CREATE_BUILD_DIR)
	@$(COPY_ASSETS)
	$(ODIN) build $(SOURCE_DIR) -out:$(PROJECT_BINARY) -debug $(PLATFORM_ODIN_FLAGS) $(ODIN_FLAGS)

run: build
	$(RUN_PROJECT)

check: rules
	$(ODIN) check $(SOURCE_DIR) $(ODIN_FLAGS)

rules:
	$(CMAKE) -S $(RULES_SOURCE_DIR) -B $(RULES_BUILD_DIR) \
		-DBUILD_TESTING=OFF \
		-DGAME_RULES_C_BUILD_EXAMPLES=OFF \
		-DCMAKE_BUILD_TYPE=Debug
	$(CMAKE) --build $(RULES_BUILD_DIR) --target game_rules_state_c

clean:
	$(CLEAN_BUILD_DIR)
