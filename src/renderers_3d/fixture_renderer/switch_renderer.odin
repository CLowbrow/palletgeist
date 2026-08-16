package fixture_renderer

import rules "../../game_rules"
import helpers "../helpers"
import rl "vendor:raylib"

SWITCH_RADIUS_RATIO :: f32(0.32)
SWITCH_MAX_HEIGHT_RATIO :: f32(0.08)

draw_switch :: proc(
	renderer: ^Renderer,
	fixture: rules.Fixture,
	ctx: ^Draw_Context,
	floor_y: f32,
	height: f32,
) {
	// Height is normalized: 0 is fully depressed and 1 is the switch's
	// deliberately short maximum height.
	normalized_height := clamp(height, f32(0), f32(1))
	model_height := normalized_height * ctx.transform.height_unit * SWITCH_MAX_HEIGHT_RATIO
	if model_height <= 0 {
		return
	}

	position := helpers.coordinate_to_world(ctx.transform, fixture.coordinate)
	position.y = floor_y + model_height * 0.5
	radius := ctx.transform.tile_size * SWITCH_RADIUS_RATIO

	rl.DrawCylinder(
		position,
		radius,
		radius,
		model_height,
		24,
		fixture_color(fixture.color),
	)
}
