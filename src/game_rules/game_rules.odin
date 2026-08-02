// Package game_rules is the Odin boundary around the C rules-engine submodule.
// Keep raw C declarations here and expose Odin-friendly wrappers to the game.
package game_rules

EXPECTED_LEGACY_API_VERSION :: u32(1)
EXPECTED_DATA_API_VERSION   :: u32(1)

Engine :: struct {
	handle: rawptr,
}

create_engine :: proc() -> (engine: Engine, ok: bool) {
	engine.handle = game_rules_engine_create()
	ok = engine.handle != nil
	return
}

destroy_engine :: proc(engine: ^Engine) {
	if engine == nil || engine.handle == nil {
		return
	}

	game_rules_engine_destroy(engine.handle)
	engine.handle = nil
}

api_is_compatible :: proc() -> bool {
	return game_rules_api_version() == EXPECTED_LEGACY_API_VERSION &&
	       game_rules_data_api_version() == EXPECTED_DATA_API_VERSION
}

legacy_api_version :: proc() -> u32 {
	return game_rules_api_version()
}

data_api_version :: proc() -> u32 {
	return game_rules_data_api_version()
}

status :: proc() -> cstring {
	return game_rules_engine_status()
}

