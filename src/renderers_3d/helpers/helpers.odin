package helpers

import rules "../../game_rules"
import "core:math"
import "core:mem"
import rl "vendor:raylib"

BASE_THICKNESS :: f32(0.12)
TICK_TIME_BUDGET :: f32(0.2) //seconds

UI_Mode :: enum {
	MainMenu,
	PauseMenu,
	LevelWon,
	LevelLost,
	Playing,
	LevelSelect,
	Animating,
}

Grid_Transform :: struct {
	coordinates: rules.Coordinate_System,
	tile_size:   f32,
	height_unit: f32,
}

coordinate_to_world :: proc(
	transform: ^Grid_Transform,
	coordinate: rules.Coordinate,
) -> rl.Vector3 {
	dx := f32(coordinate.x - transform.coordinates.origin.x)
	dy := f32(coordinate.y - transform.coordinates.origin.y)

	x_sign: f32 = 1
	z_sign: f32 = -1

	return rl.Vector3{dx * x_sign * transform.tile_size, 0, dy * z_sign * transform.tile_size}
}

ticks_view :: proc(result: ^rules.Move_Result) -> []rules.Tick {
	if result == nil || result.tick_count == 0 || result.ticks == nil {
		return nil
	}

	return mem.slice_ptr(result.ticks, int(result.tick_count))
}

events_view :: proc(tick: ^rules.Tick) -> []rules.Event {
	if tick == nil || tick.event_count == 0 || tick.events == nil {
		return nil
	}

	return mem.slice_ptr(tick.events, int(tick.event_count))
}

Entity_Pose :: struct {
	position: rl.Vector3,
	rotation: f32, //optional except player
}

Turn_Animation_Queue :: struct {
	ticks:        []rules.Tick,
	tick_index:   int,
	tick_elapsed: f32,
	animating:    bool,
}

entity_bottom_to_world :: proc(
	transform: ^Grid_Transform,
	coordinate: rules.Coordinate,
	bottom_half_steps: i32,
) -> rl.Vector3 {
	position := coordinate_to_world(transform, coordinate)
	position.y = BASE_THICKNESS + f32(bottom_half_steps) * transform.height_unit * 0.5
	return position
}

populate_entity_poses :: proc(
	poses: ^map[u64]Entity_Pose,
	current_tick: ^rules.Tick,
	progress: f32,
	transform: ^Grid_Transform,
) {
	clear(poses)

	if current_tick == nil {
		return
	}

	t := clamp(progress, f32(0), f32(1))
	eased := t * t * (3 - 2 * t)

	for event in events_view(current_tick) {
		if event.kind != .Entity_Moved {
			continue
		}

		from_position := entity_bottom_to_world(transform, event.from, event.old_bottom_half_steps)

		to_position := entity_bottom_to_world(transform, event.to, event.new_bottom_half_steps)

		pose := Entity_Pose {
			position = {
				math.lerp(from_position.x, to_position.x, eased),
				math.lerp(from_position.y, to_position.y, eased),
				math.lerp(from_position.z, to_position.z, eased),
			},
		}

		map_insert(poses, event.entity_id, pose)
	}
}
