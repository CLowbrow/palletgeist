// Package static_level_renderer renders the non-moving level geometry: floors and ramps.
package static_level_renderer

import model "../../game_state"
import rules "../../game_rules"
import helpers "../helpers"
import rl "vendor:raylib"

FLAT_BASE_THICKNESS :: f32(0.12)

Renderer :: struct {
	transform: helpers.Grid_Transform,
}

init :: proc(renderer: ^Renderer) {
	renderer.transform.tile_size = 1.0
	renderer.transform.height_unit = 1.0
}

unload :: proc(renderer: ^Renderer) {
	renderer.transform = {}
}

load_level :: proc(renderer: ^Renderer, state: ^model.World_State) {
	if current, ok := model.snapshot(state); ok {
		renderer.transform.coordinates = current.level.coordinates
	}
}

world_bounds :: proc(
	renderer: ^Renderer,
	state: ^model.World_State,
) -> (bounds: rl.BoundingBox, ok: bool) {
	current, loaded := model.snapshot(state)
	if !loaded || current.level.width == 0 || current.level.height == 0 {
		return
	}
	level := &current.level

	origin := renderer.transform.coordinates.origin
	opposite := rules.Coordinate {
		origin.x + i32(level.width) - 1,
		origin.y + i32(level.height) - 1,
	}
	first := helpers.coordinate_to_world(&renderer.transform, origin)
	last := helpers.coordinate_to_world(&renderer.transform, opposite)
	half_tile := renderer.transform.tile_size * 0.5

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
		height := surface_height(renderer, cell.elevation)
		if cell.kind == .Ramp {
			height += renderer.transform.height_unit
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

draw :: proc(renderer: ^Renderer, state: ^model.World_State) {
	current, loaded := model.snapshot(state)
	if !loaded {
		return
	}

	for cell in rules.cells_view(&current.level) {
		switch cell.kind {
		case .Flat:
			draw_flat(renderer, cell)
		case .Ramp:
			draw_ramp(renderer, cell)
		}
	}
}

draw_quad :: proc(a, b, c, d: rl.Vector3, color: rl.Color) {
	// Counter-clockwise when viewed from outside the solid.
	rl.DrawTriangle3D(a, b, c, color)
	rl.DrawTriangle3D(a, c, d, color)
}

draw_ramp :: proc(renderer: ^Renderer, cell: rules.Cell) {
	center := helpers.coordinate_to_world(&renderer.transform, cell.coordinate)
	half := renderer.transform.tile_size * 0.5

	x_min := center.x - half
	x_max := center.x + half
	z_min := center.z - half // North
	z_max := center.z + half // South

	low_y := surface_height(renderer, cell.elevation)
	high_y := low_y + renderer.transform.height_unit

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
	draw_quad(t_nw, t_sw, t_se, t_ne, rl.LIGHTGRAY)
}

draw_flat :: proc(renderer: ^Renderer, cell: rules.Cell) {
	center := helpers.coordinate_to_world(&renderer.transform, cell.coordinate)
	half := renderer.transform.tile_size * 0.5
	top_y := surface_height(renderer, cell.elevation)

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
	draw_quad(t_nw, t_sw, t_se, t_ne, rl.LIGHTGRAY)
}

surface_height :: proc(renderer: ^Renderer, elevation: i32) -> f32 {
	return FLAT_BASE_THICKNESS + f32(elevation) * renderer.transform.height_unit
}
