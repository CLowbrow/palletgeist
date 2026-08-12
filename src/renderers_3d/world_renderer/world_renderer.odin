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
	boxes:        object.Box_Renderer,
	barrels:      object.Barrel_Renderer,
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

load_level :: proc(renderer: ^Renderer, state: ^model.World_State) {
	static_level.load_level(&renderer.static_level, state)
	update_player_target(renderer, state)
	if bounds, ok := static_level.world_bounds(&renderer.static_level, state); ok {
		camera.fit_bounds(&renderer.camera, bounds)
	}
}

update_player :: proc(renderer: ^Renderer, state: ^model.World_State, direction: rules.Direction) {
	player.face(&renderer.player, direction)
	update_player_target(renderer, state)
}

get_objects :: proc(snapshot: ^rules.Snapshot) -> helpers.SortedObjects {
	objects := helpers.SortedObjects{}

	for entity in rules.entities_view(&snapshot.resolved) {
		if (entity.kind == .Player) {
			objects.player = entity
		} else if (entity.kind == .Box) {
			append(&objects.boxes, entity)
		} else if (entity.kind == .Barrel) {
			append(&objects.barrels, entity)
		}
	}
	return objects
}

draw :: proc(renderer: ^Renderer, state: ^model.World_State, mode: helpers.UI_Mode) {
	snapshot, loaded := model.snapshot(state)
	if !loaded {
		return
	}

	camera.update_position(&renderer.camera, mode)
	camera.begin(&renderer.camera)
	defer camera.end()

	// TODO: add this to renderer to stop allocate/free every frame
	objects := get_objects(snapshot)
	defer {
		delete(objects.boxes)
		delete(objects.barrels)
	}

	static_level.draw(&renderer.static_level, &snapshot.level)
	player.draw(&renderer.player, &objects.player, &renderer.static_level.transform)
	object.draw_boxes(&renderer.boxes, &objects.boxes, &renderer.static_level.transform)
	object.draw_barrels(&renderer.barrels, &objects.barrels, &renderer.static_level.transform)
}

update_player_target :: proc(renderer: ^Renderer, state: ^model.World_State) {
	if target, ok := player.camera_target(state, &renderer.static_level.transform); ok {
		renderer.camera.player_target = target
	}
}
