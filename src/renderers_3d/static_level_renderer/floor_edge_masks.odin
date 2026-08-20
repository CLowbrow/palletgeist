package static_level_renderer

import rules "../../game_rules"
import rl "vendor:raylib"

EDGE_NORTH :: u8(1 << 0)
EDGE_EAST :: u8(1 << 1)
EDGE_SOUTH :: u8(1 << 2)
EDGE_WEST :: u8(1 << 3)
EDGE_MASK_COUNT :: 16

FLOOR_EDGE_TEXTURE_PATHS := [EDGE_MASK_COUNT]cstring {
	"assets/floor_edges/edge_none.png",
	"assets/floor_edges/edge_n.png",
	"assets/floor_edges/edge_e.png",
	"assets/floor_edges/edge_ne.png",
	"assets/floor_edges/edge_s.png",
	"assets/floor_edges/edge_ns.png",
	"assets/floor_edges/edge_es.png",
	"assets/floor_edges/edge_nes.png",
	"assets/floor_edges/edge_w.png",
	"assets/floor_edges/edge_nw.png",
	"assets/floor_edges/edge_ew.png",
	"assets/floor_edges/edge_new.png",
	"assets/floor_edges/edge_sw.png",
	"assets/floor_edges/edge_nsw.png",
	"assets/floor_edges/edge_esw.png",
	"assets/floor_edges/edge_nesw.png",
}

Renderer :: struct {
	// Textures are shared by every tile with the same set of closed edges, so
	// there can never be more than 16 cached GPU textures.
	floor_textures:  [EDGE_MASK_COUNT]rl.Texture2D,
	// Indexed by the level's row-major coordinate offset and rebuilt only when
	// a level loads. Movement snapshots do not need to touch this cache.
	cell_edge_masks: []u8,
}

init :: proc(renderer: ^Renderer) {
	// Edge overlays are loaded lazily for the masks used by each level.
}

unload :: proc(renderer: ^Renderer) {
	if renderer == nil {
		return
	}

	delete(renderer.cell_edge_masks)
	for texture in renderer.floor_textures {
		if texture.id != 0 {
			rl.UnloadTexture(texture)
		}
	}
	renderer^ = {}
}

load_level :: proc(renderer: ^Renderer, level: ^rules.Level) {
	if renderer == nil {
		return
	}

	delete(renderer.cell_edge_masks)
	renderer.cell_edge_masks = nil
	if level == nil || level.width == 0 || level.height == 0 {
		return
	}

	cell_count := int(level.width) * int(level.height)
	renderer.cell_edge_masks = make([]u8, cell_count)
	for cell in rules.cells_view(level) {
		index, found := cell_index(level, cell.coordinate)
		if !found {
			continue
		}

		mask := closed_edge_mask(level, cell)
		renderer.cell_edge_masks[index] = mask
		ensure_floor_texture(renderer, mask)
	}
}

floor_texture :: proc(
	renderer: ^Renderer,
	level: ^rules.Level,
	coordinate: rules.Coordinate,
) -> rl.Texture2D {
	if renderer == nil {
		return {}
	}
	if index, found := cell_index(level, coordinate);
	   found && index < len(renderer.cell_edge_masks) {
		mask := renderer.cell_edge_masks[index]
		return renderer.floor_textures[int(mask)]
	}
	return {}
}

ensure_floor_texture :: proc(renderer: ^Renderer, mask: u8) {
	texture := &renderer.floor_textures[int(mask)]
	if texture.id != 0 {
		return
	}

	// The source asset stays as a transparent black overlay so it is easy to
	// combine with future handmade textures. For today's one-texture lighting
	// shader, turn that alpha into an opaque multiplicative mask at load time:
	// transparent becomes white and increasingly opaque black becomes gray.
	image := rl.LoadImage(FLOOR_EDGE_TEXTURE_PATHS[int(mask)])
	if !rl.IsImageValid(image) {
		return
	}
	defer rl.UnloadImage(image)

	colors := rl.LoadImageColors(image)
	if colors == nil {
		return
	}
	defer rl.UnloadImageColors(colors)

	pixel_count := int(image.width) * int(image.height)
	for index in 0 ..< pixel_count {
		value := 255 - colors[index].a
		colors[index] = rl.Color{value, value, value, 255}
	}
	opaque_mask := rl.Image {
		data    = colors,
		width   = image.width,
		height  = image.height,
		mipmaps = 1,
		format  = .UNCOMPRESSED_R8G8B8A8,
	}
	texture^ = rl.LoadTextureFromImage(opaque_mask)
	if texture.id != 0 {
		rl.SetTextureFilter(texture^, .BILINEAR)
		rl.SetTextureWrap(texture^, .CLAMP)
	}
}

closed_edge_mask :: proc(level: ^rules.Level, cell: rules.Cell) -> u8 {
	mask: u8
	directions := [4]rules.Direction{.North, .East, .South, .West}

	for direction in directions {
		coordinate, stepped := step_coordinate(level, cell.coordinate, direction)
		neighbor, found := find_cell(level, coordinate)
		if !stepped || !found || !cells_connect(cell, neighbor^, direction) {
			mask |= texture_edge(level, direction)
		}
	}
	return mask
}

texture_edge :: proc(level: ^rules.Level, direction: rules.Direction) -> u8 {
	switch direction {
	case .North:
		return level.coordinates.positive_y == .North ? EDGE_NORTH : EDGE_SOUTH
	case .East:
		return level.coordinates.positive_x == .East ? EDGE_EAST : EDGE_WEST
	case .South:
		return level.coordinates.positive_y == .South ? EDGE_NORTH : EDGE_SOUTH
	case .West:
		return level.coordinates.positive_x == .West ? EDGE_EAST : EDGE_WEST
	}
	return 0
}

cells_connect :: proc(source, destination: rules.Cell, direction: rules.Direction) -> bool {
	if source.kind == .Flat && destination.kind == .Flat {
		return source.elevation == destination.elevation
	}

	if source.kind == .Ramp && destination.kind == .Ramp {
		if source.low_direction == destination.low_direction &&
		   source.elevation == destination.elevation {
			return true
		}

		source_height, source_high, source_ok := ramp_endpoint(source, direction)
		destination_height, destination_high, destination_ok := ramp_endpoint(
			destination,
			opposite(direction),
		)
		return(
			source_ok &&
			destination_ok &&
			source_high != destination_high &&
			source_height == destination_height \
		)
	}

	if source.kind == .Ramp {
		height, _, found := ramp_endpoint(source, direction)
		return found && height == destination.elevation
	}

	height, _, found := ramp_endpoint(destination, opposite(direction))
	return found && source.elevation == height
}

ramp_endpoint :: proc(
	ramp: rules.Cell,
	direction: rules.Direction,
) -> (
	height: i32,
	high, found: bool,
) {
	if ramp.kind != .Ramp {
		return
	}
	if direction == ramp.low_direction {
		return ramp.elevation, false, true
	}
	if direction == opposite(ramp.low_direction) {
		return ramp.elevation + 1, true, true
	}
	return
}

is_ramp_endpoint :: proc(ramp: rules.Cell, direction: rules.Direction) -> bool {
	_, _, found := ramp_endpoint(ramp, direction)
	return found
}

opposite :: proc(direction: rules.Direction) -> rules.Direction {
	return rules.Direction((u32(direction) + 2) % 4)
}

step_coordinate :: proc(
	level: ^rules.Level,
	coordinate: rules.Coordinate,
	direction: rules.Direction,
) -> (
	result: rules.Coordinate,
	ok: bool,
) {
	if level == nil {
		return
	}

	x := i64(coordinate.x)
	y := i64(coordinate.y)
	switch direction {
	case .North:
		if level.coordinates.positive_y == .North {
			y += 1
		} else {
			y -= 1
		}
	case .East:
		if level.coordinates.positive_x == .East {
			x += 1
		} else {
			x -= 1
		}
	case .South:
		if level.coordinates.positive_y == .South {
			y += 1
		} else {
			y -= 1
		}
	case .West:
		if level.coordinates.positive_x == .West {
			x += 1
		} else {
			x -= 1
		}
	}

	if x < i64(min(i32)) || x > i64(max(i32)) || y < i64(min(i32)) || y > i64(max(i32)) {
		return
	}
	result = {i32(x), i32(y)}
	ok = true
	return
}

cell_index :: proc(
	level: ^rules.Level,
	coordinate: rules.Coordinate,
) -> (
	index: int,
	found: bool,
) {
	if level == nil {
		return
	}

	dx := i64(coordinate.x) - i64(level.coordinates.origin.x)
	dy := i64(coordinate.y) - i64(level.coordinates.origin.y)
	if dx < 0 || dy < 0 || dx >= i64(level.width) || dy >= i64(level.height) {
		return
	}
	return int(dy * i64(level.width) + dx), true
}

find_cell :: proc(
	level: ^rules.Level,
	coordinate: rules.Coordinate,
) -> (
	cell: ^rules.Cell,
	found: bool,
) {
	index, in_bounds := cell_index(level, coordinate)
	if !in_bounds {
		return
	}

	cells := rules.cells_view(level)
	if index < len(cells) && cells[index].coordinate == coordinate {
		return &cells[index], true
	}

	// Valid rules snapshots are row-major, but retaining this fallback keeps the
	// helper useful with hand-built levels in tests and tools.
	for &candidate in cells {
		if candidate.coordinate == coordinate {
			return &candidate, true
		}
	}
	return
}
