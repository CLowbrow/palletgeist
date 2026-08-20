package world_renderer

import rules "../../game_rules"
import model "../../game_state"
import app "../../helpers"
import fixture "../fixture_renderer"
import render "../helpers"
import object "../object_renderer"
import player "../player_renderer"
import static_level "../static_level_renderer"
import camera "../world_camera"
import rl "vendor:raylib"

Renderer :: struct {
	camera:       camera.Camera,
	transform:    render.Grid_Transform,
	static_level: static_level.Renderer,
	fixtures:     fixture.Renderer,
	player:       player.Renderer,
	objects:      object.Renderer,
	entity_poses: map[u64]render.Entity_Pose,
	lighting:     Lighting,
	post_process: Post_Process,
	snapCamera:   bool,
}

init :: proc(renderer: ^Renderer) {
	renderer.transform.tile_size = 1.0
	renderer.transform.height_unit = 1.0
	renderer.snapCamera = true
	renderer.entity_poses = make(map[u64]render.Entity_Pose)
	init_lighting(&renderer.lighting)
	init_post_process(&renderer.post_process)
	camera.init(&renderer.camera)
	static_level.init(&renderer.static_level)
	fixture.init(&renderer.fixtures)
	player.init(&renderer.player)
	object.init(&renderer.objects)
	if renderer.lighting.ready {
		player.set_shader(&renderer.player, renderer.lighting.shader)
		object.set_shader(&renderer.objects, renderer.lighting.shader)
	}
}

unload :: proc(renderer: ^Renderer) {
	delete(renderer.entity_poses)
	object.unload(&renderer.objects)
	player.unload(&renderer.player)
	fixture.unload(&renderer.fixtures)
	static_level.unload(&renderer.static_level)
	unload_post_process(&renderer.post_process)
	unload_lighting(&renderer.lighting)
}

load_level :: proc(renderer: ^Renderer, state: ^model.World_State) {
	if current, ok := model.snapshot(state); ok {
		renderer.transform.coordinates = current.level.coordinates
		static_level.load_level(&renderer.static_level, &current.level)
	}
	player.face(&renderer.player, player.DEFAULT_DIRECTION)
	update_player_target(renderer, state)
	if bounds, ok := static_level.world_bounds(&renderer.static_level, state, &renderer.transform);
	   ok {
		camera.fit_bounds(&renderer.camera, bounds)
		fit_light_to_bounds(&renderer.lighting, bounds)
	}
	renderer.snapCamera = true
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

	camera.update_position(&renderer.camera, mode, renderer.snapCamera)
	renderer.snapCamera = false
	render_to_texture := prepare_post_process(&renderer.post_process)
	if renderer.lighting.ready {
		// The lighting shader cannot sample the shadow map during this pass: its
		// texture unit is unbound, and binding the active depth target would create
		// an invalid OpenGL feedback loop. Use the model's normal shaders instead.
		player.restore_model_shaders(&renderer.player)
		object.restore_model_shaders(&renderer.objects)
		begin_shadow_pass(&renderer.lighting)
		draw_scene(renderer, &frame, render_resolved, true)
		end_shadow_pass(&renderer.lighting)

		if render_to_texture {
			begin_scene_pass(&renderer.post_process)
		}
		rl.ClearBackground(rl.Color{20, 22, 28, 255})
		player.set_shader(&renderer.player, renderer.lighting.shader)
		object.set_shader(&renderer.objects, renderer.lighting.shader)
		begin_lit_pass(&renderer.lighting)
		camera.begin(&renderer.camera)
		draw_scene(renderer, &frame, render_resolved, false)
		camera.end()
		end_lit_pass(&renderer.lighting)
	} else {
		if render_to_texture {
			begin_scene_pass(&renderer.post_process)
		}
		rl.ClearBackground(rl.Color{20, 22, 28, 255})
		camera.begin(&renderer.camera)
		draw_scene(renderer, &frame, render_resolved, false)
		camera.end()
	}

	if render_to_texture {
		end_scene_pass_and_present(&renderer.post_process)
	}
}

draw_scene :: proc(
	renderer: ^Renderer,
	frame: ^render.Frame,
	resolved: ^rules.Resolved_State,
	shadow_pass: bool,
) {
	static_level.draw(&renderer.static_level, frame)
	if player_entity, ok := model.player_from_resolved(resolved); ok {
		player.draw(&renderer.player, &player_entity, frame)
	}
	object.draw(&renderer.objects, rules.entities_view(resolved), frame)
	fixture.draw(&renderer.fixtures, frame, shadow_pass)
}

update_player_target :: proc(renderer: ^Renderer, state: ^model.World_State) {
	if target, ok := player.camera_target(state, &renderer.transform); ok {
		renderer.camera.player_target = target
	}
}
