package object_renderer

import rules "../../game_rules"
import helpers "../helpers"

Renderer :: struct {
	boxes:   Box_Renderer,
	barrels: Barrel_Renderer,
}

draw :: proc(
	renderer: ^Renderer,
	resolved: ^rules.Resolved_State,
	transform: ^helpers.Grid_Transform,
) {
	for entity in rules.entities_view(resolved) {
		switch entity.kind {
		case .Box:
			draw_box(&renderer.boxes, entity, transform)
		case .Barrel:
			draw_barrel(&renderer.barrels, entity, transform)
		case .Player:
			// The player has its own renderer and render state.
		}
	}
}
