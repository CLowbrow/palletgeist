package main
import helpers "helpers"

update_move_animation :: proc(game: ^Game_State, dt: f32) {
	queue := &game.animation_queue
	if !queue.animating {
		return
	}

	queue.tick_elapsed += dt

	// Use a loop in case one unusually long frame crosses multiple ticks.
	for queue.tick_elapsed >= helpers.TICK_TIME_BUDGET {
		queue.tick_elapsed -= helpers.TICK_TIME_BUDGET
		queue.tick_index += 1

		if queue.tick_index >= len(queue.ticks) {
			clear_move_animation(game)
			return
		}
	}
}
