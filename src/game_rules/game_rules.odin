// Package game_rules is the Odin boundary around the C rules-engine submodule.
// Keep raw C declarations here and expose Odin-friendly wrappers to the game.
package game_rules

import "base:runtime"
import "core:strings"

EXPECTED_LEGACY_API_VERSION :: u32(1)
EXPECTED_DATA_API_VERSION :: u32(1)

Engine :: struct {
	handle: rawptr,
}

// Values match GAME_RULES_DIRECTION_* in the C ABI.
Direction :: enum u32 {
	North = 0,
	East  = 1,
	South = 2,
	West  = 3,
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

load_level_json :: proc(engine: ^Engine, level_json: []u8) -> (response: string, ok: bool) {
	if engine == nil || engine.handle == nil || len(level_json) == 0 {
		return "", false
	}
	if u64(len(level_json)) > u64(max(u32)) {
		return "", false
	}

	c_response := game_rules_engine_load_level(
		engine.handle,
		raw_data(level_json),
		u32(len(level_json)),
	)
	return clone_response(c_response)
}

get_state :: proc(engine: ^Engine, result: ^State_Result) -> Call_Status {
	if result == nil || result.owned_storage != nil {
		return .Invalid_Argument
	}

	handle: rawptr
	if engine != nil {
		handle = engine.handle
	}
	return Call_Status(game_rules_engine_get_state_data(handle, result))
}

dispose_state_result :: proc(result: ^State_Result) {
	game_rules_state_result_dispose(result)
}

move :: proc(engine: ^Engine, direction: Direction, result: ^Move_Result) -> Call_Status {
	if result == nil || result.owned_storage != nil {
		return .Invalid_Argument
	}

	handle: rawptr
	if engine != nil {
		handle = engine.handle
	}
	return Call_Status(game_rules_engine_move_data(handle, u32(direction), result))
}

dispose_move_result :: proc(result: ^Move_Result) {
	game_rules_move_result_dispose(result)
}

rewind :: proc(engine: ^Engine) -> (response: string, ok: bool) {
	if engine == nil || engine.handle == nil {
		return "", false
	}

	return clone_response(game_rules_engine_rewind(engine.handle))
}

clone_response :: proc(c_response: cstring) -> (response: string, ok: bool) {
	if c_response == nil {
		return "", false
	}
	defer game_rules_string_free(c_response)

	clone_error: runtime.Allocator_Error
	response, clone_error = strings.clone_from_cstring(c_response)
	if clone_error != nil {
		return "", false
	}
	return response, true
}

api_is_compatible :: proc() -> bool {
	return(
		game_rules_api_version() == EXPECTED_LEGACY_API_VERSION &&
		game_rules_data_api_version() == EXPECTED_DATA_API_VERSION \
	)
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
