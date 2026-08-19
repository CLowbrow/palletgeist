// Package world_camera owns the fixed camera used by the shared 3D world render pass.
package world_camera

import helpers "../../helpers"
import "core:math"
import rl "vendor:raylib"

PLAYER_VIEW_SPAN :: f32(2.5)
MIN_LEVEL_VIEW_SPAN :: f32(4)
FOV :: f32(35)

// Max changes to camera position assuming 60fps
MAX_POSITION_CHANGE :: f32(0.5)
MAX_TARGET_CHANGE :: f32(0.15)
MAX_FOV_CHANGE :: f32(1)

Camera :: struct {
	render_camera:   rl.Camera3D,
	level_target:    rl.Vector3,
	level_view_span: f32,
	player_target:   rl.Vector3,
	camera_next:     rl.Camera3D,
}

Angle :: enum {
	High,
	Low,
}

init :: proc(camera: ^Camera) {
	camera.render_camera.up = rl.Vector3{0, 1, 0}
}

unload :: proc(Camera: ^Camera) {

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
	rl.BeginMode3D(camera.render_camera)
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
	camera.camera_next.target = target
	camera.camera_next.fovy = FOV
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

	camera.camera_next.position = rl.Vector3{target.x, target.y + y_offset, target.z + z_offset}
}


// Want to zoom in on the player model whenever you're not playing
update_position :: proc(camera: ^Camera, mode: helpers.UI_Mode, immediate: bool) {
	if mode == .Playing || mode == .LevelSelect {
		focus_level(camera)
	} else {
		focus_player(camera)
	}

	if (immediate) {
		move_camera_immediate(camera)
	} else {
		move_camera(camera)
	}
}

move_camera_immediate :: proc(camera: ^Camera) {
	camera.render_camera.position = camera.camera_next.position
	camera.render_camera.fovy = camera.camera_next.fovy
	camera.render_camera.target = camera.camera_next.target
}

move_camera :: proc(camera: ^Camera) {
	frame_scale := rl.GetFrameTime() * 60

	position_frames :=
		rl.Vector3Distance(camera.render_camera.position, camera.camera_next.position) /
		MAX_POSITION_CHANGE
	target_frames :=
		rl.Vector3Distance(camera.render_camera.target, camera.camera_next.target) /
		MAX_TARGET_CHANGE
	fov_frames := abs(camera.camera_next.fovy - camera.render_camera.fovy) / MAX_FOV_CHANGE
	frames_remaining := max(position_frames, target_frames, fov_frames)

	progress := f32(1)
	if frames_remaining > frame_scale {
		progress = frame_scale / frames_remaining
	}

	camera.render_camera.position +=
		(camera.camera_next.position - camera.render_camera.position) * progress
	camera.render_camera.target +=
		(camera.camera_next.target - camera.render_camera.target) * progress
	camera.render_camera.fovy += (camera.camera_next.fovy - camera.render_camera.fovy) * progress
}
