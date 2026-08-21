PROJECT := palletgeist
SOURCE_DIR := src
BUILD_DIR := build
RULES_SOURCE_DIR := bomb-box-rules-c
RULES_BUILD_DIR := $(BUILD_DIR)/game-rules
RULES_LIBRARY := $(RULES_BUILD_DIR)/libgame_rules_state_c.a

ifeq ($(OS),Windows_NT)
PROJECT_BINARY := $(BUILD_DIR)/$(PROJECT).exe
CREATE_BUILD_DIR = if not exist "$(BUILD_DIR)" mkdir "$(BUILD_DIR)"
RUN_PROJECT = "$(PROJECT_BINARY)"
CLEAN_BUILD_DIR = if exist "$(BUILD_DIR)" rmdir /S /Q "$(BUILD_DIR)"
else
PROJECT_BINARY := $(BUILD_DIR)/$(PROJECT)
CREATE_BUILD_DIR = mkdir -p "$(BUILD_DIR)"
RUN_PROJECT = ./$(PROJECT_BINARY)
CLEAN_BUILD_DIR = rm -rf "$(BUILD_DIR)"
endif

ODIN ?= odin
CMAKE ?= cmake
ODIN_FLAGS ?=

.PHONY: all build run check rules clean

all: build

build: rules
	@$(CREATE_BUILD_DIR)
	$(ODIN) build $(SOURCE_DIR) -out:$(PROJECT_BINARY) -debug $(ODIN_FLAGS)

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
