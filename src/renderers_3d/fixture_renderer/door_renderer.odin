package fixture_renderer

import rules "../../game_rules"
import helpers "../helpers"
import "core:slice"
import rl "vendor:raylib"
import rlgl "vendor:raylib/rlgl"

DOOR_FOOTPRINT_RATIO :: f32(0.82)
DOOR_VERTEX_SHADER_PATH :: "assets/shaders/door_wave.vs"
DOOR_FRAGMENT_SHADER_PATH :: "assets/shaders/door_wave.fs"

Door_Panel :: struct {
	bottom_left:  rl.Vector3,
	bottom_right: rl.Vector3,
	top_right:    rl.Vector3,
	top_left:     rl.Vector3,
	bottom_color: rl.Color,
	top_color:    rl.Color,
	camera_depth: f32,
}

collect_door_panels :: proc(
	panels: ^[dynamic]Door_Panel,
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

	// Front (+Z), back (-Z), right (+X), and left (-X). The vertices wind
	// counter-clockwise when viewed from outside the door.
	append(panels, Door_Panel {
		bottom_left  = {min_x, bottom_y, max_z},
		bottom_right = {max_x, bottom_y, max_z},
		top_right    = {max_x, top_y, max_z},
		top_left     = {min_x, top_y, max_z},
		bottom_color = bottom_color,
		top_color    = top_color,
	})
	append(panels, Door_Panel {
		bottom_left  = {max_x, bottom_y, min_z},
		bottom_right = {min_x, bottom_y, min_z},
		top_right    = {min_x, top_y, min_z},
		top_left     = {max_x, top_y, min_z},
		bottom_color = bottom_color,
		top_color    = top_color,
	})
	append(panels, Door_Panel {
		bottom_left  = {max_x, bottom_y, max_z},
		bottom_right = {max_x, bottom_y, min_z},
		top_right    = {max_x, top_y, min_z},
		top_left     = {max_x, top_y, max_z},
		bottom_color = bottom_color,
		top_color    = top_color,
	})
	append(panels, Door_Panel {
		bottom_left  = {min_x, bottom_y, min_z},
		bottom_right = {min_x, bottom_y, max_z},
		top_right    = {min_x, top_y, max_z},
		top_left     = {min_x, top_y, min_z},
		bottom_color = bottom_color,
		top_color    = top_color,
	})
}

draw_door_panels :: proc(renderer: ^Renderer, panels: []Door_Panel) {
	if len(panels) == 0 {
		return
	}

	view := rlgl.GetMatrixModelview()
	for &panel in panels {
		center := (panel.bottom_left + panel.bottom_right + panel.top_right + panel.top_left) * 0.25
		panel.camera_depth = rl.Vector3Transform(center, view).z
	}

	// Camera-space forward is -Z, so the more-negative depth is farther away.
	slice.sort_by(panels, proc(a, b: Door_Panel) -> bool {
		return a.camera_depth < b.camera_depth
	})

	// Transparent fragments must not write depth: otherwise the invisible top of
	// a door would still hide geometry rendered behind it. Flush on both sides so
	// the depth-mask change applies only to the sorted transparent panel batch.
	rlgl.DrawRenderBatchActive()
	rlgl.DisableDepthMask()

	using_door_shader := rl.IsShaderValid(renderer.door_shader)
	if using_door_shader {
		time := f32(rl.GetTime())
		rl.SetShaderValue(
			renderer.door_shader,
			renderer.door_time_location,
			&time,
			.FLOAT,
		)
		rl.BeginShaderMode(renderer.door_shader)
	}

	for panel in panels {
		draw_door_panel(panel)
	}

	rlgl.DrawRenderBatchActive()
	if using_door_shader {
		rl.EndShaderMode()
	}
	rlgl.EnableDepthMask()
}

draw_door_panel :: proc(panel: Door_Panel) {
	edge_horizontal := panel.bottom_right - panel.bottom_left
	edge_vertical := panel.top_right - panel.bottom_left
	normal := rl.Vector3Normalize(rl.Vector3CrossProduct(edge_horizontal, edge_vertical))

	rlgl.Begin(rlgl.TRIANGLES)
	rlgl.Normal3f(normal.x, normal.y, normal.z)

	draw_door_vertex(panel.bottom_left, {0, 1}, panel.bottom_color)
	draw_door_vertex(panel.bottom_right, {1, 1}, panel.bottom_color)
	draw_door_vertex(panel.top_right, {1, 0}, panel.top_color)

	draw_door_vertex(panel.bottom_left, {0, 1}, panel.bottom_color)
	draw_door_vertex(panel.top_right, {1, 0}, panel.top_color)
	draw_door_vertex(panel.top_left, {0, 0}, panel.top_color)

	// Emit the inward-facing side too. Back-face culling would otherwise make
	// panels disappear whenever the camera can see into the door's open shell.
	rlgl.Normal3f(-normal.x, -normal.y, -normal.z)

	draw_door_vertex(panel.bottom_left, {0, 1}, panel.bottom_color)
	draw_door_vertex(panel.top_left, {0, 0}, panel.top_color)
	draw_door_vertex(panel.top_right, {1, 0}, panel.top_color)

	draw_door_vertex(panel.bottom_left, {0, 1}, panel.bottom_color)
	draw_door_vertex(panel.top_right, {1, 0}, panel.top_color)
	draw_door_vertex(panel.bottom_right, {1, 1}, panel.bottom_color)

	rlgl.End()
}

draw_door_vertex :: proc(position: rl.Vector3, texcoord: rl.Vector2, color: rl.Color) {
	rlgl.Color4ub(color.r, color.g, color.b, color.a)
	rlgl.TexCoord2f(texcoord.x, texcoord.y)
	rlgl.Vertex3f(position.x, position.y, position.z)
}
