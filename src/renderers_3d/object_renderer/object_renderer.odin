package object_renderer

import rules "../../game_rules"
import helpers "../helpers"

Renderer :: struct {}

draw :: proc(
	renderer: ^Renderer,
	entities: []rules.Entity,
	transform: ^helpers.Grid_Transform,
	poses: ^map[u64]helpers.Entity_Pose,
) {
	for entity in entities {
		switch entity.kind {
		case .Box:
			draw_box(entity, transform, poses)
		case .Barrel:
			draw_barrel(entity, transform, poses)
		case .Player:
		// The player has its own renderer and render state.
		}
	}
}
