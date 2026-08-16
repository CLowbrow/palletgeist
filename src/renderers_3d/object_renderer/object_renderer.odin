package object_renderer

import rules "../../game_rules"
import helpers "../helpers"

Renderer :: struct {}

draw :: proc(
	renderer: ^Renderer,
	entities: []rules.Entity,
	frame: ^helpers.Frame,
) {
	for entity in entities {
		switch entity.kind {
		case .Box:
			draw_box(entity, frame)
		case .Barrel:
			draw_barrel(entity, frame)
		case .Player:
		// The player has its own renderer and render state.
		}
	}
}
