package fixture_renderer

import rules "../../game_rules"
import helpers "../helpers"
import rl "vendor:raylib"

Renderer :: struct {}

init :: proc(renderer: ^Renderer) {
	// TODO: Load shared fixture models, materials, or shaders here.
}

unload :: proc(renderer: ^Renderer) {
	// TODO: Unload resources owned by the fixture renderer here.
}

draw :: proc(
	renderer: ^Renderer,
	frame: ^helpers.Frame,
) {
	if renderer == nil || frame == nil || frame.level == nil || frame.state_before == nil ||
	   frame.state_after == nil || frame.transform == nil {
		return
	}

	for fixture in rules.fixtures_view(frame.level) {
		floor_y, found := fixture_floor_y(frame.level, fixture.coordinate, frame.transform)
		if !found {
			continue
		}

		switch fixture.kind {
		case .Switch:
			pressed_before := rules.switch_is_pressed(
				frame.level,
				frame.state_before,
				fixture.coordinate,
			)
			pressed_after := rules.switch_is_pressed(
				frame.level,
				frame.state_after,
				fixture.coordinate,
			)
			draw_switch(renderer, fixture, frame, floor_y, pressed_before, pressed_after)
		case .Door:
			open_before := rules.door_is_open(frame.state_before, fixture.coordinate)
			open_after := rules.door_is_open(frame.state_after, fixture.coordinate)
			draw_door(renderer, fixture, frame, floor_y, open_before, open_after)
		case .Exit:
			draw_exit(renderer, fixture, frame, floor_y)
		}
	}
}

fixture_floor_y :: proc(
	level: ^rules.Level,
	coordinate: rules.Coordinate,
	transform: ^helpers.Grid_Transform,
) -> (
	floor_y: f32,
	found: bool,
) {
	for cell in rules.cells_view(level) {
		if cell.coordinate == coordinate {
			floor_y = helpers.BASE_THICKNESS + f32(cell.elevation) * transform.height_unit
			found = true
			return
		}
	}

	return
}

animated_retraction_height :: proc(
	retracted_before: bool,
	retracted_after: bool,
	progress: f32,
) -> f32 {
	height_before: f32 = 1
	if retracted_before {
		height_before = 0
	}

	height_after: f32 = 1
	if retracted_after {
		height_after = 0
	}

	// Animations happen at the very end of the window cuz it looks better
	t := clamp(progress * 3 - 2, f32(0), f32(1))
	eased := t * t * (3 - 2 * t)
	return height_before + (height_after - height_before) * eased
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
