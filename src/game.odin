package main
import "core:fmt"
import "core:log"
import rules "game_rules"
import model "game_state"
import helpers "renderers_3d/helpers"
import world "renderers_3d/world_renderer"

clear_move_animation :: proc(game: ^Game_State) {
	game.animation_queue = {}
	rules.dispose_move_result(&game.retained_result)
}

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

	clear_move_animation(game)
	world.load_level(&game.world_renderer, &game.world_state)
	game.current_level = level_index

	return true
}

apply_move :: proc(game: ^Game_State, direction: rules.Direction) {
	result: rules.Move_Result
	call := rules.move(&game.engine, direction, &result)
	defer rules.dispose_move_result(&result)

	if call != .Ok {
		log.errorf("Rules move call failed: %v", call)
		return
	}

	if result.has_state != 0 {
		if !model.refresh(&game.world_state, &game.engine) {
			log.error("Could not retain the current rules state")
			return
		}
	}

	game.animation_queue = {}
	rules.dispose_move_result(&game.retained_result)

	clear_move_animation(game)

	game.animation_queue = {
		ticks      = helpers.ticks_view(&game.retained_result),
		tick_index = 0,
		animating  = true,
	}

	world.update_player(&game.world_renderer, &game.world_state, direction)
}

apply_rewind :: proc(game: ^Game_State) {
	result: rules.Rewind_Result
	call := rules.rewind(&game.engine, &result)
	defer rules.dispose_rewind_result(&result)
	if call != .Ok {
		log.errorf("Rules rewind call failed: %v", call)
		return
	}

	log.infof(
		"Rewind: status=%v accepted=%v events=%d",
		result.status,
		result.accepted != 0,
		result.event_count,
	)

	if result.has_state != 0 {
		if !model.refresh(&game.world_state, &game.engine) {
			log.error("Could not retain the rewound rules state")
			return
		}
		clear_move_animation(game)
		world.refresh_player(&game.world_renderer, &game.world_state)
	}
}
