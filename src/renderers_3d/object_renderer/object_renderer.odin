package object_renderer

import rules "../../game_rules"
import helpers "../helpers"
import rl "vendor:raylib"

Renderer :: struct {
	barrel: Barrel_Renderer,
}

init :: proc(renderer: ^Renderer) {
	barrel_init(&renderer.barrel)
}

unload :: proc(renderer: ^Renderer) {
	barrel_unload(&renderer.barrel)
}

set_shader :: proc(renderer: ^Renderer, shader: rl.Shader) {
	barrel_set_shader(&renderer.barrel, shader)
}

restore_model_shaders :: proc(renderer: ^Renderer) {
	barrel_restore_model_shaders(&renderer.barrel)
}

draw :: proc(renderer: ^Renderer, entities: []rules.Entity, frame: ^helpers.Frame) {
	for entity in entities {
		switch entity.kind {
		case .Box:
			draw_box(entity, frame)
		case .Barrel:
			draw_barrel(&renderer.barrel, entity, frame)
		case .Player:
		// The player has its own renderer and render state.
		}
	}
}
