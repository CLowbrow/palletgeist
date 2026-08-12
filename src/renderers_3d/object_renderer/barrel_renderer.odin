package object_renderer

import rules "../../game_rules"
import helpers "../helpers"
import rl "vendor:raylib"

Barrel_Renderer :: struct {
	// TODO: maybe put stuff in here?
}

draw_barrels :: proc(
	renderer: ^Barrel_Renderer,
	barrels: ^[dynamic]rules.Entity,
	transform: ^helpers.Grid_Transform,
) {
	for barrel in barrels^ {
		position := helpers.coordinate_to_world(transform, barrel.coordinate)
		position.y =
			helpers.BASE_THICKNESS +
			f32(barrel.bottom_half_steps) * transform.height_unit * 0.5 +
			transform.height_unit * 0.25

		radius := transform.tile_size * 0.35
		rl.DrawCylinder(position, radius, radius, transform.height_unit * 0.5, 16, rl.RED)
	}
}
