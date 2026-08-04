package world_renderer

import rules "../../game_rules"
import static_level "../static_level_renderer"
import camera "../world_camera"

Renderer :: struct {
	camera:       camera.Camera,
	static_level: static_level.Renderer,
}

init :: proc(renderer: ^Renderer) {
	camera.init(&renderer.camera)
	static_level.init(&renderer.static_level)
}

unload :: proc(renderer: ^Renderer) {
	static_level.unload(&renderer.static_level)
}

load_level :: proc(renderer: ^Renderer, level: ^rules.Level) {
	static_level.load_level(&renderer.static_level, level)
	if bounds, ok := static_level.world_bounds(&renderer.static_level); ok {
		camera.fit_bounds(&renderer.camera, bounds)
	}
}

draw :: proc(renderer: ^Renderer) {
	camera.begin(&renderer.camera)
	defer camera.end()

	static_level.draw(&renderer.static_level)
	// TODO: Draw more stuff
}
