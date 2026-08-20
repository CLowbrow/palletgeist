package fixture_renderer

import rules "../../game_rules"
import helpers "../helpers"
import "core:c"
import "core:log"
import rl "vendor:raylib"

Renderer :: struct {
	door_panels:        [dynamic]Door_Panel,
	door_shader:        rl.Shader,
	door_time_location: c.int,
}

init :: proc(renderer: ^Renderer) {
	renderer.door_panels = make([dynamic]Door_Panel, 0, 16)
	renderer.door_shader = rl.LoadShader(DOOR_VERTEX_SHADER_PATH, DOOR_FRAGMENT_SHADER_PATH)
	if rl.IsShaderValid(renderer.door_shader) {
		renderer.door_time_location = rl.GetShaderLocation(renderer.door_shader, "time")
	} else {
		log.error("Could not load the animated door shader; using normal rendering")
	}
}

unload :: proc(renderer: ^Renderer) {
	delete(renderer.door_panels)
	if rl.IsShaderValid(renderer.door_shader) {
		rl.UnloadShader(renderer.door_shader)
	}
	renderer^ = {}
}

draw :: proc(renderer: ^Renderer, frame: ^helpers.Frame, shadow_pass: bool) {
	if renderer == nil ||
	   frame == nil ||
	   frame.level == nil ||
	   frame.state_before == nil ||
	   frame.state_after == nil ||
	   frame.transform == nil {
		return
	}

	clear(&renderer.door_panels)

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
			if (shadow_pass) {
				break
			}
			open_before := rules.door_is_open(frame.state_before, fixture.coordinate)
			open_after := rules.door_is_open(frame.state_after, fixture.coordinate)
			collect_door_panels(
				&renderer.door_panels,
				fixture,
				frame,
				floor_y,
				open_before,
				open_after,
			)
		case .Exit:
			draw_exit(renderer, fixture, frame, floor_y)
		}
	}

	// Doors are translucent, so render all of their panels together after the
	// opaque fixtures and in back-to-front camera order.
	draw_door_panels(renderer, renderer.door_panels[:])
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
	height_before: f32 = 3
	if retracted_before {
		height_before = 0
	}

	height_after: f32 = 3
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
