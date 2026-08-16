package fixture_renderer

import rules "../../game_rules"
import helpers "../helpers"
import rl "vendor:raylib"

EXIT_RADIUS_RATIO :: f32(0.34)
EXIT_HEIGHT_RATIO :: f32(0.55)

draw_exit :: proc(
	renderer: ^Renderer,
	fixture: rules.Fixture,
	ctx: ^Draw_Context,
	floor_y: f32,
) {
	position := helpers.coordinate_to_world(ctx.transform, fixture.coordinate)
	height := ctx.transform.height_unit * EXIT_HEIGHT_RATIO
	position.y = floor_y + height * 0.5
	radius := ctx.transform.tile_size * EXIT_RADIUS_RATIO

	// A four-sided cylinder with a zero-radius top is a square pyramid.
	rl.DrawCylinder(position, 0, radius, height, 4, rl.PURPLE)
}
