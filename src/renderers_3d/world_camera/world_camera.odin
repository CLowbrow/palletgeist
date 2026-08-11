// Package world_camera owns the fixed camera used by the shared 3D world render pass.
package world_camera

import helpers "../helpers"
import "core:math"
import rl "vendor:raylib"

PLAYER_VIEW_SPAN :: f32(2.5)
MIN_LEVEL_VIEW_SPAN :: f32(4)
FOV :: f32(35)

Camera :: struct {
	raylib:          rl.Camera3D,
	level_target:    rl.Vector3,
	level_view_span: f32,
	player_target:   rl.Vector3,
}

Angle :: enum {
	High,
	Low,
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
	focus(camera, camera.level_target, max(camera.level_view_span, MIN_LEVEL_VIEW_SPAN), .High)
}

focus_player :: proc(camera: ^Camera) {
	focus(camera, camera.player_target, PLAYER_VIEW_SPAN, .Low)
}

focus :: proc(camera: ^Camera, target: rl.Vector3, view_span: f32, angle: Angle) {
	camera.raylib.target = target
	camera.raylib.fovy = FOV
	half_fov_radians := FOV * 0.5 * math.PI / 180.0
	distance := view_span / 2 / math.tan(half_fov_radians) * 1.2

	// Geometric!
	sqrt_5 := f32(math.sqrt(f32(5)))
	y_offset := distance / sqrt_5
	z_offset := distance * 2 / sqrt_5
	if (angle == .High) {
		y_offset = distance * 2 / sqrt_5
		z_offset = distance / sqrt_5
	}

	camera.raylib.position = rl.Vector3{target.x, target.y + y_offset, target.z + z_offset}
}


// Want to zoom in on the player model whenever you're not playing
update_position :: proc(camera: ^Camera, mode: helpers.UI_Mode) {
	if mode == .Playing {
		focus_level(camera)
	} else {
		focus_player(camera)
	}
}
