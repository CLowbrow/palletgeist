package render_helpers

import rules "../../game_rules"
import project "../../helpers"
import "core:math"
import rl "vendor:raylib"

BASE_THICKNESS :: f32(0.12)

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

Entity_Pose :: struct {
	position: rl.Vector3,
	rotation: f32, //optional except player
}

// Frame is the immutable view shared by every renderer for one world draw.
// The world renderer owns the transform and pose map referenced here.
Frame :: struct {
	level:        ^rules.Level,
	state_before: ^rules.Resolved_State,
	state_after:  ^rules.Resolved_State,
	progress:     f32,
	transform:    ^Grid_Transform,
	poses:        ^map[u64]Entity_Pose,
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

	for event in project.events_view(current_tick) {
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
