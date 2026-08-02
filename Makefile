PROJECT := palletgeist
SOURCE_DIR := src
BUILD_DIR := build
RULES_SOURCE_DIR := bomb-box-rules-c
RULES_BUILD_DIR := $(BUILD_DIR)/game-rules
RULES_LIBRARY := $(RULES_BUILD_DIR)/libgame_rules_state_c.a

ODIN ?= odin
CMAKE ?= cmake
ODIN_FLAGS ?=

.PHONY: all build run check rules clean

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

clean:
	rm -rf $(BUILD_DIR)

