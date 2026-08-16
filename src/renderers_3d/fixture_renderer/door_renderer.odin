package fixture_renderer

import rules "../../game_rules"
import helpers "../helpers"
import rl "vendor:raylib"

DOOR_FOOTPRINT_RATIO :: f32(0.82)

draw_door :: proc(
	renderer: ^Renderer,
	fixture: rules.Fixture,
	ctx: ^Draw_Context,
	floor_y: f32,
	open_before: bool,
	open_after: bool,
) {
	// Height is normalized: 0 is fully retracted and 1 is one complete stage
	// level (Grid_Transform.height_unit).
	height := animated_retraction_height(open_before, open_after, ctx.progress)
	normalized_height := clamp(height, f32(0), f32(1))
	model_height := normalized_height * ctx.transform.height_unit
	if model_height <= 0 {
		return
	}

	position := helpers.coordinate_to_world(ctx.transform, fixture.coordinate)
	position.y = floor_y + model_height * 0.5
	footprint := ctx.transform.tile_size * DOOR_FOOTPRINT_RATIO

	rl.DrawCube(
		position,
		footprint,
		model_height,
		footprint,
		fixture_color(fixture.color),
	)
}
