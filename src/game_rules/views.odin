package game_rules

import "core:mem"

// These slices are immutable views into a result's owned_storage. They must not
// be retained after the owning result is disposed or replaced.
cells_view :: proc(level: ^Level) -> []Cell {
	if level == nil || level.cell_count == 0 || level.cells == nil {
		return nil
	}
	return mem.slice_ptr(level.cells, int(level.cell_count))
}

fixtures_view :: proc(level: ^Level) -> []Fixture {
	if level == nil || level.fixture_count == 0 || level.fixtures == nil {
		return nil
	}
	return mem.slice_ptr(level.fixtures, int(level.fixture_count))
}

entities_view :: proc(state: ^Resolved_State) -> []Entity {
	if state == nil || state.entity_count == 0 || state.entities == nil {
		return nil
	}
	return mem.slice_ptr(state.entities, int(state.entity_count))
}

armed_barrel_ids_view :: proc(state: ^Resolved_State) -> []u64 {
	if state == nil || state.armed_barrel_count == 0 || state.armed_barrel_ids == nil {
		return nil
	}
	return mem.slice_ptr(state.armed_barrel_ids, int(state.armed_barrel_count))
}

active_switch_colors_view :: proc(state: ^Resolved_State) -> []Color {
	if state == nil || state.active_switch_color_count == 0 || state.active_switch_colors == nil {
		return nil
	}
	return mem.slice_ptr(state.active_switch_colors, int(state.active_switch_color_count))
}

open_doors_view :: proc(state: ^Resolved_State) -> []Coordinate {
	if state == nil || state.open_door_count == 0 || state.open_doors == nil {
		return nil
	}
	return mem.slice_ptr(state.open_doors, int(state.open_door_count))
}
