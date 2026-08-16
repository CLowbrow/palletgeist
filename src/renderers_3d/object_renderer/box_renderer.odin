package object_renderer

import rules "../../game_rules"
import helpers "../helpers"
import rl "vendor:raylib"


draw_box :: proc(box: rules.Entity, frame: ^helpers.Frame) {
	position := helpers.entity_bottom_to_world(
		frame.transform,
		box.coordinate,
		box.bottom_half_steps,
	)
	if pose, found := frame.poses[box.id]; found {
		position = pose.position
	}
	box_height := frame.transform.height_unit * 0.5
	position.y += box_height * 0.5

	width := frame.transform.tile_size * 0.7
	rl.DrawCube(position, width, box_height, width, rl.BROWN)
}
