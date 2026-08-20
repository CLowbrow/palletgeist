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

load_level_json_data :: proc(
	engine: ^Engine,
	level_json: []u8,
	result: ^JSON_Load_Result,
) -> Call_Status {
	if result == nil || result.owned_storage != nil {
		return .Invalid_Argument
	}
	if len(level_json) == 0 || u64(len(level_json)) > u64(max(u32)) {
		return .Invalid_Argument
	}

	handle: rawptr
	if engine != nil {
		handle = engine.handle
	}
	return Call_Status(
		game_rules_engine_load_level_json_data(
			handle,
			raw_data(level_json),
			u32(len(level_json)),
			result,
		),
	)
}

dispose_json_load_result :: proc(result: ^JSON_Load_Result) {
	game_rules_json_load_result_dispose(result)
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

rewind :: proc(engine: ^Engine, result: ^Rewind_Result) -> Call_Status {
	if result == nil || result.owned_storage != nil {
		return .Invalid_Argument
	}

	handle: rawptr
	if engine != nil {
		handle = engine.handle
	}
	return Call_Status(game_rules_engine_rewind_data(handle, result))
}

dispose_rewind_result :: proc(result: ^Rewind_Result) {
	game_rules_rewind_result_dispose(result)
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

ramp_endpoint :: proc(ramp: Cell, direction: Direction) -> (height: i32, high, found: bool) {
	if ramp.kind != .Ramp {
		return
	}
	if direction == ramp.low_direction {
		return ramp.elevation, false, true
	}
	if direction == opposite(ramp.low_direction) {
		return ramp.elevation + 1, true, true
	}
	return
}

is_ramp_endpoint :: proc(ramp: Cell, direction: Direction) -> bool {
	_, _, found := ramp_endpoint(ramp, direction)
	return found
}

opposite :: proc(direction: Direction) -> Direction {
	return Direction((u32(direction) + 2) % 4)
}

step_coordinate :: proc(
	level: ^Level,
	coordinate: Coordinate,
	direction: Direction,
) -> (
	result: Coordinate,
	ok: bool,
) {
	if level == nil {
		return
	}

	x := i64(coordinate.x)
	y := i64(coordinate.y)
	switch direction {
	case .North:
		if level.coordinates.positive_y == .North {
			y += 1
		} else {
			y -= 1
		}
	case .East:
		if level.coordinates.positive_x == .East {
			x += 1
		} else {
			x -= 1
		}
	case .South:
		if level.coordinates.positive_y == .South {
			y += 1
		} else {
			y -= 1
		}
	case .West:
		if level.coordinates.positive_x == .West {
			x += 1
		} else {
			x -= 1
		}
	}

	if x < i64(min(i32)) || x > i64(max(i32)) || y < i64(min(i32)) || y > i64(max(i32)) {
		return
	}
	result = {i32(x), i32(y)}
	ok = true
	return
}

cell_index :: proc(level: ^Level, coordinate: Coordinate) -> (index: int, found: bool) {
	if level == nil {
		return
	}

	dx := i64(coordinate.x) - i64(level.coordinates.origin.x)
	dy := i64(coordinate.y) - i64(level.coordinates.origin.y)
	if dx < 0 || dy < 0 || dx >= i64(level.width) || dy >= i64(level.height) {
		return
	}
	return int(dy * i64(level.width) + dx), true
}

find_cell :: proc(level: ^Level, coordinate: Coordinate) -> (cell: ^Cell, found: bool) {
	index, in_bounds := cell_index(level, coordinate)
	if !in_bounds {
		return
	}

	cells := cells_view(level)
	if index < len(cells) && cells[index].coordinate == coordinate {
		return &cells[index], true
	}

	// Valid rules snapshots are row-major, but retaining this fallback keeps the
	// helper useful with hand-built levels in tests and tools.
	for &candidate in cells {
		if candidate.coordinate == coordinate {
			return &candidate, true
		}
	}
	return
}
