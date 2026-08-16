package world_renderer

import rules "../../game_rules"
import model "../../game_state"
import app "../../helpers"
import render "../helpers"
import fixture "../fixture_renderer"
import object "../object_renderer"
import player "../player_renderer"
import static_level "../static_level_renderer"
import camera "../world_camera"

Renderer :: struct {
	camera:       camera.Camera,
	transform:    render.Grid_Transform,
	static_level: static_level.Renderer,
	fixtures:     fixture.Renderer,
	player:       player.Renderer,
	objects:      object.Renderer,
	entity_poses: map[u64]render.Entity_Pose,
}

init :: proc(renderer: ^Renderer) {
	renderer.transform.tile_size = 1.0
	renderer.transform.height_unit = 1.0
	renderer.entity_poses = make(map[u64]render.Entity_Pose)
	camera.init(&renderer.camera)
	static_level.init(&renderer.static_level)
	fixture.init(&renderer.fixtures)
	player.init(&renderer.player)
}

unload :: proc(renderer: ^Renderer) {
	delete(renderer.entity_poses)
	player.unload(&renderer.player)
	fixture.unload(&renderer.fixtures)
	static_level.unload(&renderer.static_level)
}

load_level :: proc(renderer: ^Renderer, state: ^model.World_State) {
	if current, ok := model.snapshot(state); ok {
		renderer.transform.coordinates = current.level.coordinates
	}
	player.face(&renderer.player, player.DEFAULT_DIRECTION)
	update_player_target(renderer, state)
	if bounds, ok := static_level.world_bounds(
		&renderer.static_level,
		state,
		&renderer.transform,
	); ok {
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
	animation_queue: ^app.Turn_Animation_Queue,
	mode: app.UI_Mode,
) {
	snapshot, loaded := model.snapshot(state)
	if !loaded {
		return
	}

	progress := animation_queue.tick_elapsed / app.TICK_TIME_BUDGET
	progress = clamp(progress, 0, 1)

	camera.update_position(&renderer.camera, mode)
	camera.begin(&renderer.camera)
	defer camera.end()

	current_tick: ^rules.Tick
	render_resolved := &snapshot.resolved

	if animation_queue.animating &&
	   animation_queue.tick_index >= 0 &&
	   animation_queue.tick_index < len(animation_queue.ticks) {
		tick_index := animation_queue.tick_index
		current_tick = &animation_queue.ticks[tick_index]

		if tick_index == 0 {
			if animation_queue.initial_state != nil {
				render_resolved = animation_queue.initial_state
			}
		} else {
			render_resolved = &animation_queue.ticks[tick_index - 1].state_after
		}
	}

	render.populate_entity_poses(
		&renderer.entity_poses,
		current_tick,
		progress,
		&renderer.transform,
	)

	state_after := render_resolved
	if current_tick != nil {
		state_after = &current_tick.state_after
	}

	frame := render.Frame {
		level        = &snapshot.level,
		state_before = render_resolved,
		state_after  = state_after,
		progress     = progress,
		transform    = &renderer.transform,
		poses        = &renderer.entity_poses,
	}

	static_level.draw(&renderer.static_level, &frame)
	fixture.draw(&renderer.fixtures, &frame)
	if player_entity, ok := model.player_from_resolved(render_resolved); ok {
		player.draw(&renderer.player, &player_entity, &frame)
	}
	object.draw(
		&renderer.objects,
		rules.entities_view(render_resolved),
		&frame,
	)
}

update_player_target :: proc(renderer: ^Renderer, state: ^model.World_State) {
	if target, ok := player.camera_target(state, &renderer.transform); ok {
		renderer.camera.player_target = target
	}
}
