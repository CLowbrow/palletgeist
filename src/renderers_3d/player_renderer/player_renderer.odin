// Package player_renderer draws the player entity using the Gorker model.
package player_renderer

import rules "../../game_rules"
import model "../../game_state"
import "../helpers"
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

draw :: proc(renderer: ^Renderer, player: ^rules.Entity, transform: ^helpers.Grid_Transform) {
	bounds := renderer.model_bounds
	model_width := bounds.max.x - bounds.min.x
	model_depth := bounds.max.z - bounds.min.z
	model_footprint := max(model_width, model_depth)
	if model_footprint <= 0 {
		return
	}

	scale := transform.tile_size * MODEL_FOOTPRINT_RATIO / model_footprint
	rotation := direction_rotation(renderer.direction)

	position := helpers.coordinate_to_world(transform, player.coordinate)
	position.y =
		helpers.BASE_THICKNESS +
		f32(player.bottom_half_steps) * transform.height_unit * 0.5 -
		bounds.min.y * scale

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
