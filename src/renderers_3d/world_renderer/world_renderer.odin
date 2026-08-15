package world_renderer

import rules "../../game_rules"
import model "../../game_state"
import helpers "../helpers"
import object "../object_renderer"
import player "../player_renderer"
import static_level "../static_level_renderer"
import camera "../world_camera"

Renderer :: struct {
	camera:       camera.Camera,
	static_level: static_level.Renderer,
	player:       player.Renderer,
	objects:      object.Renderer,
	entity_poses: map[u64]helpers.Entity_Pose,
}

init :: proc(renderer: ^Renderer) {
	renderer.entity_poses = make(map[u64]helpers.Entity_Pose)
	camera.init(&renderer.camera)
	static_level.init(&renderer.static_level)
	player.init(&renderer.player)
}

unload :: proc(renderer: ^Renderer) {
	delete(renderer.entity_poses)
	player.unload(&renderer.player)
	static_level.unload(&renderer.static_level)
}

load_level :: proc(renderer: ^Renderer, state: ^model.World_State) {
	static_level.load_level(&renderer.static_level, state)
	player.face(&renderer.player, player.DEFAULT_DIRECTION)
	update_player_target(renderer, state)
	if bounds, ok := static_level.world_bounds(&renderer.static_level, state); ok {
		camera.fit_bounds(&renderer.camera, bounds)
	}
}

update_player :: proc(renderer: ^Renderer, state: ^model.World_State, direction: rules.Direction) {
	player.face(&renderer.player, direction)
	update_player_target(renderer, state)
}

refresh_player :: proc(renderer: ^Renderer, state: ^model.World_State) {
	update_player_target(renderer, state)
}

draw :: proc(
	renderer: ^Renderer,
	state: ^model.World_State,
	animation_queue: ^helpers.Turn_Animation_Queue,
	mode: helpers.UI_Mode,
) {
	snapshot, loaded := model.snapshot(state)
	if !loaded {
		return
	}

	progress := animation_queue.tick_elapsed / helpers.TICK_TIME_BUDGET
	progress = clamp(progress, 0, 1)

	camera.update_position(&renderer.camera, mode)
	camera.begin(&renderer.camera)
	defer camera.end()

	current_tick: rules.Tick

	if len(animation_queue.ticks) > 0 &&
	   animation_queue.animating &&
	   animation_queue.tick_index >= 0 &&
	   animation_queue.tick_index < len(animation_queue.ticks) {
		current_tick = animation_queue.ticks[animation_queue.tick_index]
	}

	helpers.populate_entity_poses(
		&renderer.entity_poses,
		&current_tick,
		progress,
		&renderer.static_level.transform,
	)

	static_level.draw(&renderer.static_level, &snapshot.level)
	if player_entity, ok := model.player(state); ok {
		player.draw(
			&renderer.player,
			&player_entity,
			&renderer.static_level.transform,
			&renderer.entity_poses,
		)
	}
	object.draw(&renderer.objects, &snapshot.resolved, &renderer.static_level.transform)
}

update_player_target :: proc(renderer: ^Renderer, state: ^model.World_State) {
	if target, ok := player.camera_target(state, &renderer.static_level.transform); ok {
		renderer.camera.player_target = target
	}
}
