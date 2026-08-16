package object_renderer

import rules "../../game_rules"
import helpers "../helpers"
import rl "vendor:raylib"

draw_barrel :: proc(
	barrel: rules.Entity,
	frame: ^helpers.Frame,
) {
	position := helpers.entity_bottom_to_world(
		frame.transform,
		barrel.coordinate,
		barrel.bottom_half_steps,
	)
	if pose, found := frame.poses[barrel.id]; found {
		position = pose.position
	}
	barrel_height := frame.transform.height_unit * 0.5
	position.y += barrel_height * 0.5

	radius := frame.transform.tile_size * 0.35
	rl.DrawCylinder(position, radius, radius, barrel_height, 16, rl.RED)
}
