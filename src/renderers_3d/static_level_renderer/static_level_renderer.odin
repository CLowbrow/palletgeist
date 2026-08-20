// Package static_level_renderer renders the non-moving level geometry: floors and ramps.
package static_level_renderer

import rules "../../game_rules"
import model "../../game_state"
import helpers "../helpers"
import rl "vendor:raylib"
import rlgl "vendor:raylib/rlgl"

world_bounds :: proc(
	renderer: ^Renderer,
	state: ^model.World_State,
	transform: ^helpers.Grid_Transform,
) -> (
	bounds: rl.BoundingBox,
	ok: bool,
) {
	current, loaded := model.snapshot(state)
	if !loaded || transform == nil || current.level.width == 0 || current.level.height == 0 {
		return
	}
	level := &current.level

	origin := transform.coordinates.origin
	opposite := rules.Coordinate{origin.x + i32(level.width) - 1, origin.y + i32(level.height) - 1}
	first := helpers.coordinate_to_world(transform, origin)
	last := helpers.coordinate_to_world(transform, opposite)
	half_tile := transform.tile_size * 0.5

	min_x, max_x := first.x, last.x
	if min_x > max_x {
		min_x, max_x = max_x, min_x
	}
	min_z, max_z := first.z, last.z
	if min_z > max_z {
		min_z, max_z = max_z, min_z
	}

	max_y: f32
	for cell in rules.cells_view(level) {
		height := surface_height(transform, cell.elevation)
		if cell.kind == .Ramp {
			height += transform.height_unit
		}
		if height > max_y {
			max_y = height
		}
	}

	bounds = rl.BoundingBox {
		min = rl.Vector3{min_x - half_tile, 0, min_z - half_tile},
		max = rl.Vector3{max_x + half_tile, max_y, max_z + half_tile},
	}
	ok = true
	return
}

draw :: proc(renderer: ^Renderer, frame: ^helpers.Frame) {
	for cell in rules.cells_view(frame.level) {
		switch cell.kind {
		case .Flat:
			draw_flat(renderer, cell, frame)
		case .Ramp:
			draw_ramp(renderer, cell, frame)
		}
	}
}

draw_floor_quad :: proc(
	renderer: ^Renderer,
	level: ^rules.Level,
	coordinate: rules.Coordinate,
	a, b, c, d: rl.Vector3,
	color: rl.Color,
) {
	texture := floor_texture(renderer, level, coordinate)

	if texture.id != 0 {
		rlgl.SetTexture(texture.id)
	}
	draw_quad(a, b, c, d, color)
	if texture.id != 0 {
		// rlSetTexture(0) does not split an active TRIANGLES batch in raylib 6,
		// so following ramp geometry would inherit this floor's edge mask.
		rlgl.SetTexture(floor_texture_reset_id(texture.id, rlgl.GetTextureIdDefault()))
	}
}

floor_texture_reset_id :: proc(mask_texture_id, default_texture_id: u32) -> u32 {
	return mask_texture_id != 0 ? default_texture_id : 0
}

draw_quad :: proc(a, b, c, d: rl.Vector3, color: rl.Color) {
	// Counter-clockwise when viewed from outside the solid.
	edge_ab := b - a
	edge_ac := c - a
	normal := rl.Vector3Normalize(rl.Vector3CrossProduct(edge_ab, edge_ac))

	rlgl.Begin(rlgl.TRIANGLES)
	rlgl.Color4ub(color.r, color.g, color.b, color.a)
	rlgl.Normal3f(normal.x, normal.y, normal.z)

	// Each face currently receives the complete texture. These coordinates can
	// later be changed to world-space tiling or atlas coordinates per face.
	draw_vertex(a, rl.Vector2{0, 0})
	draw_vertex(b, rl.Vector2{0, 1})
	draw_vertex(c, rl.Vector2{1, 1})
	draw_vertex(a, rl.Vector2{0, 0})
	draw_vertex(c, rl.Vector2{1, 1})
	draw_vertex(d, rl.Vector2{1, 0})

	rlgl.End()
}

draw_gradient_quad :: proc(a, b, c, d: rl.Vector3, color_a, color_b, color_c, color_d: rl.Color) {
	edge_ab := b - a
	edge_ac := c - a
	normal := rl.Vector3Normalize(rl.Vector3CrossProduct(edge_ab, edge_ac))

	rlgl.Begin(rlgl.TRIANGLES)
	rlgl.Normal3f(normal.x, normal.y, normal.z)

	draw_colored_vertex(a, {0, 0}, color_a)
	draw_colored_vertex(b, {0, 1}, color_b)
	draw_colored_vertex(c, {1, 1}, color_c)

	draw_colored_vertex(a, {0, 0}, color_a)
	draw_colored_vertex(c, {1, 1}, color_c)
	draw_colored_vertex(d, {1, 0}, color_d)

	rlgl.End()
}

draw_colored_vertex :: proc(position: rl.Vector3, texcoord: rl.Vector2, color: rl.Color) {
	rlgl.Color4ub(color.r, color.g, color.b, color.a)
	rlgl.TexCoord2f(texcoord.x, texcoord.y)
	rlgl.Vertex3f(position.x, position.y, position.z)
}

draw_vertex :: proc(position: rl.Vector3, texcoord: rl.Vector2) {
	rlgl.TexCoord2f(texcoord.x, texcoord.y)
	rlgl.Vertex3f(position.x, position.y, position.z)
}

draw_ramp :: proc(renderer: ^Renderer, cell: rules.Cell, frame: ^helpers.Frame) {
	center := helpers.coordinate_to_world(frame.transform, cell.coordinate)
	half := frame.transform.tile_size * 0.5

	x_min := center.x - half
	x_max := center.x + half
	z_min := center.z - half // North
	z_max := center.z + half // South

	low_y := surface_height(frame.transform, cell.elevation)
	high_y := low_y + frame.transform.height_unit
	low_value := u8(200 - 10 * cell.elevation)
	high_value := u8(200 - 10 * (cell.elevation + 1))

	low_color := rl.Color{low_value, low_value, low_value, 255}
	high_color := rl.Color{high_value, high_value, high_value, 255}

	color_nw := high_color
	color_ne := high_color
	color_se := high_color
	color_sw := high_color

	switch cell.low_direction {
	case .North:
		color_nw = low_color
		color_ne = low_color
	case .East:
		color_ne = low_color
		color_se = low_color
	case .South:
		color_se = low_color
		color_sw = low_color
	case .West:
		color_sw = low_color
		color_nw = low_color
	}

	// All ramp solids begin at the same y=0 plane as flat cubes.
	b_nw := rl.Vector3{x_min, 0, z_min}
	b_ne := rl.Vector3{x_max, 0, z_min}
	b_se := rl.Vector3{x_max, 0, z_max}
	b_sw := rl.Vector3{x_min, 0, z_max}

	t_nw := rl.Vector3{x_min, high_y, z_min}
	t_ne := rl.Vector3{x_max, high_y, z_min}
	t_se := rl.Vector3{x_max, high_y, z_max}
	t_sw := rl.Vector3{x_min, high_y, z_max}

	switch cell.low_direction {
	case .North:
		t_nw.y = low_y
		t_ne.y = low_y
	case .East:
		t_ne.y = low_y
		t_se.y = low_y
	case .South:
		t_se.y = low_y
		t_sw.y = low_y
	case .West:
		t_sw.y = low_y
		t_nw.y = low_y
	}

	// Bottom and four vertical sides.
	draw_quad(b_nw, b_ne, b_se, b_sw, rl.DARKGRAY)
	// TODO: Can't see this one but put it back if we ever rotate
	// draw_quad(b_nw, t_nw, t_ne, b_ne, rl.DARKGRAY) // North
	draw_quad(b_ne, t_ne, t_se, b_se, rl.DARKGRAY) // East
	draw_quad(b_se, t_se, t_sw, b_sw, rl.DARKGRAY) // South
	draw_quad(b_sw, t_sw, t_nw, b_nw, rl.DARKGRAY) // West

	// Top
	draw_gradient_quad(t_nw, t_sw, t_se, t_ne, color_nw, color_sw, color_se, color_ne)
}

draw_flat :: proc(renderer: ^Renderer, cell: rules.Cell, frame: ^helpers.Frame) {
	center := helpers.coordinate_to_world(frame.transform, cell.coordinate)
	half := frame.transform.tile_size * 0.5
	top_y := surface_height(frame.transform, cell.elevation)
	top_color := rl.Color {
		u8(200 - 10 * cell.elevation),
		u8(200 - 10 * cell.elevation),
		u8(200 - 10 * cell.elevation),
		255,
	}


	x_min := center.x - half
	x_max := center.x + half
	z_min := center.z - half // North
	z_max := center.z + half // South

	b_nw := rl.Vector3{x_min, 0, z_min}
	b_ne := rl.Vector3{x_max, 0, z_min}
	b_se := rl.Vector3{x_max, 0, z_max}
	b_sw := rl.Vector3{x_min, 0, z_max}

	t_nw := rl.Vector3{x_min, top_y, z_min}
	t_ne := rl.Vector3{x_max, top_y, z_min}
	t_se := rl.Vector3{x_max, top_y, z_max}
	t_sw := rl.Vector3{x_min, top_y, z_max}

	draw_quad(b_nw, b_ne, b_se, b_sw, rl.DARKGRAY)
	// TODO: Can't see this one but put it back if we ever rotate
	// draw_quad(b_nw, t_nw, t_ne, b_ne, rl.DARKGRAY) // North
	draw_quad(b_ne, t_ne, t_se, b_se, rl.DARKGRAY) // East
	draw_quad(b_se, t_se, t_sw, b_sw, rl.DARKGRAY) // South
	draw_quad(b_sw, t_sw, t_nw, b_nw, rl.DARKGRAY) // West
	draw_floor_quad(renderer, frame.level, cell.coordinate, t_nw, t_sw, t_se, t_ne, top_color)
}

surface_height :: proc(transform: ^helpers.Grid_Transform, elevation: i32) -> f32 {
	return helpers.BASE_THICKNESS + f32(elevation) * transform.height_unit
}
