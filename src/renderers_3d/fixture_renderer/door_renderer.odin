package fixture_renderer

import rules "../../game_rules"
import helpers "../helpers"
import rl "vendor:raylib"
import rlgl "vendor:raylib/rlgl"

DOOR_FOOTPRINT_RATIO :: f32(0.82)

draw_door :: proc(
	renderer: ^Renderer,
	fixture: rules.Fixture,
	ctx: ^helpers.Frame,
	floor_y: f32,
	open_before: bool,
	open_after: bool,
) {
	// Height is normalized: 0 is fully retracted and 1 is one complete stage
	// level (Grid_Transform.height_unit).
	height := animated_retraction_height(open_before, open_after, ctx.progress)
	normalized_height := clamp(height, f32(0), f32(3))
	model_height := normalized_height * ctx.transform.height_unit
	if model_height <= 0 {
		return
	}

	position := helpers.coordinate_to_world(ctx.transform, fixture.coordinate)
	footprint := ctx.transform.tile_size * DOOR_FOOTPRINT_RATIO
	half_footprint := footprint * 0.5
	bottom_y := floor_y
	top_y := floor_y + model_height

	min_x := position.x - half_footprint
	max_x := position.x + half_footprint
	min_z := position.z - half_footprint
	max_z := position.z + half_footprint

	bottom_color := fixture_color(fixture.color)
	top_color := bottom_color
	top_color.a = 0

	// Transparent fragments must not write depth: otherwise the invisible top of
	// the door would still hide geometry rendered behind it. Flush on both sides
	// so the depth-mask change applies only to these four panels.
	rlgl.DrawRenderBatchActive()
	rlgl.DisableDepthMask()

	// Front (+Z), back (-Z), right (+X), and left (-X). The vertices wind
	// counter-clockwise when viewed from outside the door.
	draw_door_panel(
		{min_x, bottom_y, max_z},
		{max_x, bottom_y, max_z},
		{max_x, top_y, max_z},
		{min_x, top_y, max_z},
		bottom_color,
		top_color,
	)
	draw_door_panel(
		{max_x, bottom_y, min_z},
		{min_x, bottom_y, min_z},
		{min_x, top_y, min_z},
		{max_x, top_y, min_z},
		bottom_color,
		top_color,
	)
	draw_door_panel(
		{max_x, bottom_y, max_z},
		{max_x, bottom_y, min_z},
		{max_x, top_y, min_z},
		{max_x, top_y, max_z},
		bottom_color,
		top_color,
	)
	draw_door_panel(
		{min_x, bottom_y, min_z},
		{min_x, bottom_y, max_z},
		{min_x, top_y, max_z},
		{min_x, top_y, min_z},
		bottom_color,
		top_color,
	)

	rlgl.DrawRenderBatchActive()
	rlgl.EnableDepthMask()
}

draw_door_panel :: proc(
	bottom_left, bottom_right, top_right, top_left: rl.Vector3,
	bottom_color, top_color: rl.Color,
) {
	edge_horizontal := bottom_right - bottom_left
	edge_vertical := top_right - bottom_left
	normal := rl.Vector3Normalize(rl.Vector3CrossProduct(edge_horizontal, edge_vertical))

	rlgl.Begin(rlgl.TRIANGLES)
	rlgl.Normal3f(normal.x, normal.y, normal.z)

	draw_door_vertex(bottom_left, {0, 1}, bottom_color)
	draw_door_vertex(bottom_right, {1, 1}, bottom_color)
	draw_door_vertex(top_right, {1, 0}, top_color)

	draw_door_vertex(bottom_left, {0, 1}, bottom_color)
	draw_door_vertex(top_right, {1, 0}, top_color)
	draw_door_vertex(top_left, {0, 0}, top_color)

	// Emit the inward-facing side too. Back-face culling would otherwise make
	// panels disappear whenever the camera can see into the door's open shell.
	rlgl.Normal3f(-normal.x, -normal.y, -normal.z)

	draw_door_vertex(bottom_left, {0, 1}, bottom_color)
	draw_door_vertex(top_left, {0, 0}, top_color)
	draw_door_vertex(top_right, {1, 0}, top_color)

	draw_door_vertex(bottom_left, {0, 1}, bottom_color)
	draw_door_vertex(top_right, {1, 0}, top_color)
	draw_door_vertex(bottom_right, {1, 1}, bottom_color)

	rlgl.End()
}

draw_door_vertex :: proc(position: rl.Vector3, texcoord: rl.Vector2, color: rl.Color) {
	rlgl.Color4ub(color.r, color.g, color.b, color.a)
	rlgl.TexCoord2f(texcoord.x, texcoord.y)
	rlgl.Vertex3f(position.x, position.y, position.z)
}
