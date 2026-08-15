package object_renderer

import rules "../../game_rules"
import helpers "../helpers"
import rl "vendor:raylib"

Barrel_Renderer :: struct {
	// TODO: maybe put stuff in here?
}

draw_barrel :: proc(
	renderer: ^Barrel_Renderer,
	barrel: rules.Entity,
	transform: ^helpers.Grid_Transform,
) {
	position := helpers.entity_bottom_to_world(
		transform,
		barrel.coordinate,
		barrel.bottom_half_steps,
	)
	barrel_height := transform.height_unit * 0.5
	position.y += barrel_height * 0.5

	radius := transform.tile_size * 0.35
	rl.DrawCylinder(position, radius, radius, barrel_height, 16, rl.RED)
}
