package fixture_renderer

import rules "../../game_rules"
import helpers "../helpers"
import rl "vendor:raylib"

Renderer :: struct {}

// Draw_Context contains both ends of the currently animated tick. When no
// tick is active, state_before and state_after point to the same state and
// progress is 0.
Draw_Context :: struct {
	state_before: ^rules.Resolved_State,
	state_after:  ^rules.Resolved_State,
	current_tick: ^rules.Tick,
	progress:     f32,
	transform:    ^helpers.Grid_Transform,
}

init :: proc(renderer: ^Renderer) {
	// TODO: Load shared fixture models, materials, or shaders here.
}

unload :: proc(renderer: ^Renderer) {
	// TODO: Unload resources owned by the fixture renderer here.
}

draw :: proc(
	renderer: ^Renderer,
	level: ^rules.Level,
	state_before: ^rules.Resolved_State,
	current_tick: ^rules.Tick,
	progress: f32,
	transform: ^helpers.Grid_Transform,
) {
	if renderer == nil || level == nil || state_before == nil || transform == nil {
		return
	}

	state_after := state_before
	if current_tick != nil {
		state_after = &current_tick.state_after
	}

	ctx := Draw_Context {
		state_before = state_before,
		state_after  = state_after,
		progress     = clamp(progress, f32(0), f32(1)),
		transform    = transform,
	}

	for fixture in rules.fixtures_view(level) {
		floor_y, found := fixture_floor_y(level, fixture.coordinate, transform)
		if !found {
			continue
		}

		switch fixture.kind {
		case .Switch:
			draw_switch(renderer, fixture, &ctx, floor_y, 1.0)
		case .Door:
			draw_door(renderer, fixture, &ctx, floor_y, 1.0)
		case .Exit:
			draw_exit(renderer, fixture, &ctx, floor_y)
		}
	}
}

fixture_floor_y :: proc(
	level: ^rules.Level,
	coordinate: rules.Coordinate,
	transform: ^helpers.Grid_Transform,
) -> (floor_y: f32, found: bool) {
	for cell in rules.cells_view(level) {
		if cell.coordinate == coordinate {
			floor_y = helpers.BASE_THICKNESS + f32(cell.elevation) * transform.height_unit
			found = true
			return
		}
	}

	return
}

fixture_color :: proc(color: rules.Color) -> rl.Color {
	switch color {
	case .Red:
		return rl.RED
	case .Green:
		return rl.GREEN
	case .Blue:
		return rl.BLUE
	case .Yellow:
		return rl.YELLOW
	}

	return rl.WHITE
}
