// Package player_renderer draws the player entity using the Gorker model.
package player_renderer

import rules "../../game_rules"
import model "../../game_state"
import "../helpers"
import "core:math"
import rl "vendor:raylib"

MODEL_PATH :: "assets/Gorker.glb"
MODEL_FOOTPRINT_RATIO :: f32(0.72)
DEFAULT_DIRECTION :: rules.Direction.South

Renderer :: struct {
	model:        rl.Model,
	model_bounds: rl.BoundingBox,
	direction:    rules.Direction,
	model_loaded: bool,
}

init :: proc(renderer: ^Renderer) {
	renderer.model = rl.LoadModel(MODEL_PATH)
	renderer.model_loaded = rl.IsModelValid(renderer.model)
	if renderer.model_loaded {
		renderer.model_bounds = rl.GetModelBoundingBox(renderer.model)
	}

	renderer.direction = DEFAULT_DIRECTION
}

unload :: proc(renderer: ^Renderer) {
	if renderer.model_loaded {
		rl.UnloadModel(renderer.model)
	}
	renderer.model_loaded = false
}

face :: proc(renderer: ^Renderer, direction: rules.Direction) {
	renderer.direction = direction
}

camera_target :: proc(
	state: ^model.World_State,
	transform: ^helpers.Grid_Transform,
) -> (
	target: rl.Vector3,
	ok: bool,
) {
	entity, player_loaded := model.player(state)
	if !player_loaded {
		return
	}

	target = helpers.coordinate_to_world(transform, entity.coordinate)
	target.y =
		helpers.BASE_THICKNESS +
		f32(entity.bottom_half_steps) * transform.height_unit * 0.5 +
		transform.height_unit * 0.5
	ok = true
	return
}

draw :: proc(
	renderer: ^Renderer,
	player: ^rules.Entity,
	transform: ^helpers.Grid_Transform,
	animation_queue: ^helpers.Turn_Animation_Queue,
	progress: f32,
) {
	bounds := renderer.model_bounds
	model_width := bounds.max.x - bounds.min.x
	model_depth := bounds.max.z - bounds.min.z
	model_footprint := max(model_width, model_depth)
	if model_footprint <= 0 {
		return
	}

	scale := transform.tile_size * MODEL_FOOTPRINT_RATIO / model_footprint
	rotation := direction_rotation(renderer.direction)

	position := helpers.entity_draw_position(
		transform,
		player.coordinate,
		player.bottom_half_steps,
		bounds.min.y,
		scale,
	)
	//find the position
	if animation_queue != nil &&
	   len(animation_queue.ticks) > 0 &&
	   animation_queue.animating &&
	   animation_queue.tick_index >= 0 &&
	   animation_queue.tick_index < len(animation_queue.ticks) {
		current_tick := &animation_queue.ticks[animation_queue.tick_index]
		events := helpers.events_view(current_tick)

		for event in helpers.events_view(current_tick) {
			if event.kind != .Entity_Moved || event.entity_id != player.id {
				continue
			}

			from_position := helpers.entity_draw_position(
				transform,
				event.from,
				event.old_bottom_half_steps,
				bounds.min.y,
				scale,
			)

			to_position := helpers.entity_draw_position(
				transform,
				event.to,
				event.new_bottom_half_steps,
				bounds.min.y,
				scale,
			)

			// Cubic ease-in-out, also known as smoothstep.
			t := clamp(progress, f32(0), f32(1))
			eased := t * t * (3 - 2 * t)

			position = rl.Vector3 {
				math.lerp(from_position.x, to_position.x, eased),
				math.lerp(from_position.y, to_position.y, eased),
				math.lerp(from_position.z, to_position.z, eased),
			}

			break
		}
	}

	rl.DrawModelEx(
		renderer.model,
		position,
		rl.Vector3{0, 1, 0},
		rotation,
		rl.Vector3{scale, scale, scale},
		rl.WHITE,
	)
}

direction_rotation :: proc(direction: rules.Direction) -> f32 {
	switch direction {
	case .North:
		return 0
	case .East:
		return -90
	case .South:
		return 180
	case .West:
		return 90
	}

	return 0
}
