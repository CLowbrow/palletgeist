// Package world_camera owns the fixed camera used by the shared 3D world render pass.
package world_camera

import "core:math"
import "core:slice"
import rl "vendor:raylib"

Camera :: struct {
	raylib:    rl.Camera3D,
	target:    rl.Vector3,
	view_span: f32,
}

init :: proc(camera: ^Camera) {
	camera.raylib.up = rl.Vector3{0, 1, 0}
}

fit_bounds :: proc(camera: ^Camera, bounds: rl.BoundingBox) {
	camera.target = rl.Vector3 {
		(bounds.min.x + bounds.max.x) * 0.5,
		(bounds.min.y + bounds.max.y) * 0.5,
		(bounds.min.z + bounds.max.z) * 0.5,
	}
	camera.view_span = max(bounds.max.z - bounds.min.z, bounds.max.x - bounds.min.x)
	update_raylib_camera(camera)
}

begin :: proc(camera: ^Camera) {
	rl.BeginMode3D(camera.raylib)
}

end :: proc() {
	rl.EndMode3D()
}

update_raylib_camera :: proc(camera: ^Camera) {
	view_span := camera.view_span
	fov := f32(35)
	if view_span < 4 {
		view_span = 4
	}
	camera.raylib.target = camera.target
	camera.raylib.fovy = fov
	half_fov_radians := fov * 0.5 * math.PI / 180.0
	distance := view_span / 2 / math.tan(half_fov_radians) * 1.2

	// Geometric!
	sqrt_5 := f32(math.sqrt(f32(5)))
	y_offset := distance * 2 / sqrt_5
	z_offset := distance / sqrt_5

	camera.raylib.position = rl.Vector3 {
		camera.target.x,
		camera.target.y + y_offset,
		camera.target.z + z_offset,
	}
}
