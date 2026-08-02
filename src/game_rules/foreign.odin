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
}

