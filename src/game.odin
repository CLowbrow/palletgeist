package main
import "core:fmt"
import model "game_state"
import rules "game_rules"
import world "renderers_3d/world_renderer"

start_level :: proc(game: ^Game_State, level_index: int) -> bool {
	// calling into c jank
	result: rules.JSON_Load_Result
	if len(EMBEDDED_LEVELS) <= level_index {
		fmt.eprintln("level select out of bounds")
		return false
	}
	status := rules.load_level_json_data(&game.engine, EMBEDDED_LEVELS[level_index].data, &result)
	defer rules.dispose_json_load_result(&result)

	if status != .Ok {
		fmt.eprintln("Could not load level")
		return false
	}

	if result.status != .Loaded || result.accepted == 0 {
		fmt.eprintln("Level was rejected:", result.status)
		return false
	}

	if result.has_state == 0 {
		fmt.eprintln("Loaded level did not return a state")
		return false
	}

	if !model.refresh(&game.world_state, &game.engine) {
		fmt.eprintln("Could not retain the loaded level state")
		return false
	}

	world.load_level(&game.world_renderer, &game.world_state)

	return true
}
