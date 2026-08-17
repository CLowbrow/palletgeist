package object_renderer

import rules "../../game_rules"
import helpers "../helpers"
import rl "vendor:raylib"

Renderer :: struct {
	barrel: Barrel_Renderer,
	box:    Box_Renderer,
}

init :: proc(renderer: ^Renderer) {
	barrel_init(&renderer.barrel)
	box_init(&renderer.box)
}

unload :: proc(renderer: ^Renderer) {
	box_unload(&renderer.box)
	barrel_unload(&renderer.barrel)
}

set_shader :: proc(renderer: ^Renderer, shader: rl.Shader) {
	barrel_set_shader(&renderer.barrel, shader)
	box_set_shader(&renderer.box, shader)
}

restore_model_shaders :: proc(renderer: ^Renderer) {
	barrel_restore_model_shaders(&renderer.barrel)
	box_restore_model_shaders(&renderer.box)
}

draw :: proc(renderer: ^Renderer, entities: []rules.Entity, frame: ^helpers.Frame) {
	for entity in entities {
		switch entity.kind {
		case .Box:
			draw_box(&renderer.box, entity, frame)
		case .Barrel:
			draw_barrel(&renderer.barrel, entity, frame)
		case .Player:
		// The player has its own renderer and render state.
		}
	}
}
