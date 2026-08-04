// Package static_level_renderer renders the non-moving level geometry: floors and ramps.
package static_level_renderer

import rules "../../game_rules"
import "core:mem"
import rl "vendor:raylib"

Grid_Transform :: struct {
	coordinates: rules.Coordinate_System,
	tile_size:   f32,
	height_unit: f32,
}

Renderer :: struct {
	cells:     []rules.Cell,
	width:     u32,
	height:    u32,
	transform: Grid_Transform,
	loaded:    bool,
}

init :: proc(renderer: ^Renderer) {
	renderer.transform.tile_size = 1.0
	renderer.transform.height_unit = 1.0
}

unload :: proc(renderer: ^Renderer) {
	if renderer.cells != nil {
		delete(renderer.cells)
	}
	renderer.cells = nil
	renderer.width = 0
	renderer.height = 0
	renderer.loaded = false
}

load_level :: proc(renderer: ^Renderer, level: ^rules.Level) {
	cell_count := int(level.cell_count)
	new_cells := make([]rules.Cell, cell_count)
	if cell_count > 0 {
		incoming_cells := mem.slice_ptr(level.cells, cell_count)
		copy(new_cells, incoming_cells)
	}

	delete(renderer.cells)
	renderer.cells = new_cells

	renderer.width = level.width
	renderer.height = level.height
	renderer.transform.coordinates = level.coordinates
	renderer.loaded = true
}

coordinate_to_world :: proc(
	transform: ^Grid_Transform,
	coordinate: rules.Coordinate,
) -> rl.Vector3 {
	dx := f32(coordinate.x - transform.coordinates.origin.x)
	dy := f32(coordinate.y - transform.coordinates.origin.y)

	x_sign: f32 = 1
	z_sign: f32 = -1

	return rl.Vector3{dx * x_sign * transform.tile_size, 0, dy * z_sign * transform.tile_size}
}

world_bounds :: proc(renderer: ^Renderer) -> (bounds: rl.BoundingBox, ok: bool) {
	origin := renderer.transform.coordinates.origin
	opposite := rules.Coordinate {
		origin.x + i32(renderer.width) - 1,
		origin.y + i32(renderer.height) - 1,
	}
	first := coordinate_to_world(&renderer.transform, origin)
	last := coordinate_to_world(&renderer.transform, opposite)
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
	for cell in renderer.cells {
		if cell.kind == .Flat {
			height := flat_thickness(cell)
			if height > max_y {
				max_y = height
			}
		}
	}

	bounds = rl.BoundingBox {
		min = rl.Vector3{min_x - half_tile, 0, min_z - half_tile},
		max = rl.Vector3{max_x + half_tile, max_y, max_z + half_tile},
	}
	ok = true
	return
}

draw :: proc(renderer: ^Renderer) {
	for cell in renderer.cells {
		switch cell.kind {
		case .Flat:
			draw_flat(renderer, cell)
		case .Ramp:
		// TODO actually draw ramps
		}
	}
}

draw_flat :: proc(renderer: ^Renderer, cell: rules.Cell) {
	position := coordinate_to_world(&renderer.transform, cell.coordinate)
	thickness := flat_thickness(cell)
	position.y = thickness * 0.5
	size := rl.Vector3 {
		renderer.transform.tile_size * 0.98,
		thickness,
		renderer.transform.tile_size * 0.98,
	}
	rl.DrawCubeV(position, size, rl.LIGHTGRAY)
	rl.DrawCubeWiresV(position, size, rl.DARKBROWN)
}

flat_thickness :: proc(cell: rules.Cell) -> f32 {
	return 0.12 + (f32(0.5) * f32(cell.elevation))
}
