// Package world_camera owns the fixed camera used by the shared 3D world render pass.
package world_camera

import "core:math"
import "core:slice"
import rl "vendor:raylib"

Camera_Mode :: enum {
	Playing,
	Menu,
}

Camera :: struct {
	raylib:          rl.Camera3D,
	level_target:    rl.Vector3,
	level_view_span: f32,
	player_target:   rl.Vector3,
	camera_mode:     Camera_Mode,
}

init :: proc(camera: ^Camera) {
	camera.raylib.up = rl.Vector3{0, 1, 0}
}

fit_bounds :: proc(camera: ^Camera, bounds: rl.BoundingBox) {
	camera.level_target = rl.Vector3 {
		(bounds.min.x + bounds.max.x) * 0.5,
		(bounds.min.y + bounds.max.y) * 0.5,
		(bounds.min.z + bounds.max.z) * 0.5,
	}
	camera.level_view_span = max(bounds.max.z - bounds.min.z, bounds.max.x - bounds.min.x)
	focus_level(camera)
}

begin :: proc(camera: ^Camera) {
	rl.BeginMode3D(camera.raylib)
}

end :: proc() {
	rl.EndMode3D()
}

focus_level :: proc(camera: ^Camera) {
	view_span := camera.level_view_span
	fov := f32(35)
	if view_span < 4 {
		view_span = 4
	}
	camera.raylib.target = camera.level_target
	camera.raylib.fovy = fov
	half_fov_radians := fov * 0.5 * math.PI / 180.0
	distance := view_span / 2 / math.tan(half_fov_radians) * 1.2

	// Geometric!
	sqrt_5 := f32(math.sqrt(f32(5)))
	y_offset := distance * 2 / sqrt_5
	z_offset := distance / sqrt_5

	camera.raylib.position = rl.Vector3 {
		camera.level_target.x,
		camera.level_target.y + y_offset,
		camera.level_target.z + z_offset,
	}
}

focus_player :: proc(camera: ^Camera) {

}

update_position :: proc(camera: ^Camera) {
	if camera.camera_mode == .Playing {
		focus_level(camera)
	} else {
		focus_player(camera)
	}
}
