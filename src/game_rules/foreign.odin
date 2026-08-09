package game_rules

// Static library paths are resolved relative to this source file.
when ODIN_OS == .Windows {
	foreign import rules_lib "../../build/game-rules/Debug/game_rules_state_c.lib"
} else {
	foreign import rules_lib "../../build/game-rules/libgame_rules_state_c.a"
}

foreign rules_lib {
	game_rules_api_version      :: proc() -> u32 ---
	game_rules_data_api_version :: proc() -> u32 ---
	game_rules_engine_status    :: proc() -> cstring ---

	game_rules_engine_create  :: proc() -> rawptr ---
	game_rules_engine_destroy :: proc(engine: rawptr) ---

	game_rules_engine_load_level :: proc(
		engine:            rawptr,
		level_json:        rawptr,
		level_json_length: u32,
	) -> cstring ---
	game_rules_engine_load_level_json_data :: proc(
		engine:            rawptr,
		level_json:        rawptr,
		level_json_length: u32,
		out_result:        ^JSON_Load_Result,
	) -> u32 ---
	game_rules_json_load_result_dispose :: proc(result: ^JSON_Load_Result) ---
	game_rules_engine_get_state_data :: proc(
		engine:     rawptr,
		out_result: ^State_Result,
	) -> u32 ---
	game_rules_state_result_dispose :: proc(result: ^State_Result) ---
	game_rules_engine_move_data :: proc(
		engine:     rawptr,
		direction:  u32,
		out_result: ^Move_Result,
	) -> u32 ---
	game_rules_move_result_dispose :: proc(result: ^Move_Result) ---
	game_rules_engine_rewind :: proc(engine: rawptr) -> cstring ---
	game_rules_string_free :: proc(result: cstring) ---
}
