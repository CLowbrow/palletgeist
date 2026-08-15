package object_renderer

import rules "../../game_rules"
import helpers "../helpers"
import rl "vendor:raylib"

Box_Renderer :: struct {
	// TODO: maybe put stuff in here?
}

draw_box :: proc(renderer: ^Box_Renderer, box: rules.Entity, transform: ^helpers.Grid_Transform) {
	position := helpers.entity_bottom_to_world(transform, box.coordinate, box.bottom_half_steps)
	box_height := transform.height_unit * 0.5
	position.y += box_height * 0.5

	width := transform.tile_size * 0.7
	rl.DrawCube(position, width, box_height, width, rl.BROWN)
}
