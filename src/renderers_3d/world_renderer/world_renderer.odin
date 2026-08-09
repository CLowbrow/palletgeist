package world_renderer

import rules "../../game_rules"
import player "../player_renderer"
import static_level "../static_level_renderer"
import camera "../world_camera"

Renderer :: struct {
	camera:       camera.Camera,
	static_level: static_level.Renderer,
	player:       player.Renderer,
}

init :: proc(renderer: ^Renderer) {
	camera.init(&renderer.camera)
	static_level.init(&renderer.static_level)
	player.init(&renderer.player)
}

unload :: proc(renderer: ^Renderer) {
	player.unload(&renderer.player)
	static_level.unload(&renderer.static_level)
}

load_level :: proc(renderer: ^Renderer, snapshot: ^rules.Snapshot) {
	static_level.load_level(&renderer.static_level, &snapshot.level)
	player.load_state(
		&renderer.player,
		&snapshot.resolved,
		renderer.static_level.transform,
	)
	if bounds, ok := static_level.world_bounds(&renderer.static_level); ok {
		camera.fit_bounds(&renderer.camera, bounds)
	}
}

update_player :: proc(
	renderer: ^Renderer,
	state: ^rules.Resolved_State,
	direction: rules.Direction,
) {
	player.load_state(&renderer.player, state, renderer.static_level.transform)
	player.face(&renderer.player, direction)
}

draw :: proc(renderer: ^Renderer) {
	camera.begin(&renderer.camera)
	defer camera.end()

	static_level.draw(&renderer.static_level)
	player.draw(&renderer.player)
}
