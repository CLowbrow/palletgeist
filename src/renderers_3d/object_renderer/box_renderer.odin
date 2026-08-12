package object_renderer

import rules "../../game_rules"
import helpers "../helpers"
import rl "vendor:raylib"

Box_Renderer :: struct {
	// TODO: maybe put stuff in here?
}

draw_boxes :: proc(
	renderer: ^Box_Renderer,
	boxes: ^[dynamic]rules.Entity,
	transform: ^helpers.Grid_Transform,
) {
	for box in boxes^ {
		position := helpers.coordinate_to_world(transform, box.coordinate)
		position.y =
			helpers.BASE_THICKNESS +
			f32(box.bottom_half_steps) * transform.height_unit * 0.5 +
			transform.height_unit * 0.25

		width := transform.tile_size * 0.7
		rl.DrawCube(position, width, transform.height_unit * 0.5, width, rl.BROWN)
	}
}
