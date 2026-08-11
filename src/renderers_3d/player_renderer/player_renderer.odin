// Package player_renderer draws the player entity using the Gorker model.
package player_renderer

import model "../../game_state"
import rules "../../game_rules"
import "../helpers"
import static_level "../static_level_renderer"
import "core:math"
import "core:mem"
import rl "vendor:raylib"
import rlgl "vendor:raylib/rlgl"

MODEL_PATH :: "assets/Gorker.glb"
MODEL_FOOTPRINT_RATIO :: f32(0.72)
// Raylib reserves material slot 0 for its default, shifting glTF materials by one.
EYE_MATERIAL_INDEX :: 5

Renderer :: struct {
	model:        rl.Model,
	model_bounds: rl.BoundingBox,
	direction:    rules.Direction,
	model_loaded: bool,
}

init :: proc(renderer: ^Renderer) {
	renderer.model = rl.LoadModel(MODEL_PATH)
	renderer.model_loaded = rl.IsModelValid(renderer.model)
	if renderer.model_loaded {
		renderer.model_bounds = rl.GetModelBoundingBox(renderer.model)

		// Material 5 is the GLB's "Eye" material after Raylib's default slot.
		// Keep the model asset intact while applying the intended in-game eye color.
		if EYE_MATERIAL_INDEX < int(renderer.model.materialCount) {
			materials := mem.slice_ptr(renderer.model.materials, int(renderer.model.materialCount))
			maps := mem.slice_ptr(materials[EYE_MATERIAL_INDEX].maps, rl.MAX_MATERIAL_MAPS)
			maps[int(rl.MaterialMapIndex.ALBEDO)].color = rl.WHITE
		}
	}

	// Player unrotated model faces east (positive X). TODO: fix it
	renderer.direction = .East
}

unload :: proc(renderer: ^Renderer) {
	if renderer.model_loaded {
		rl.UnloadModel(renderer.model)
	}
	renderer.model_loaded = false
}

face :: proc(renderer: ^Renderer, direction: rules.Direction) {
	renderer.direction = direction
}

camera_target :: proc(
	state: ^model.World_State,
	transform: ^helpers.Grid_Transform,
) -> (target: rl.Vector3, ok: bool) {
	entity, player_loaded := model.player(state)
	if !player_loaded {
		return
	}

	target = helpers.coordinate_to_world(transform, entity.coordinate)
	target.y =
		static_level.FLAT_BASE_THICKNESS +
		f32(entity.bottom_half_steps) * transform.height_unit * 0.5 +
		transform.height_unit * 0.5
	ok = true
	return
}

draw :: proc(
	renderer: ^Renderer,
	state: ^model.World_State,
	transform: ^helpers.Grid_Transform,
) {
	entity, player_loaded := model.player(state)
	if !renderer.model_loaded || !player_loaded {
		return
	}

	bounds := renderer.model_bounds
	model_width := bounds.max.x - bounds.min.x
	model_depth := bounds.max.z - bounds.min.z
	model_footprint := max(model_width, model_depth)
	if model_footprint <= 0 {
		return
	}

	scale := transform.tile_size * MODEL_FOOTPRINT_RATIO / model_footprint
	rotation := direction_rotation(renderer.direction)
	model_center_x := (bounds.min.x + bounds.max.x) * 0.5 * scale
	model_center_z := (bounds.min.z + bounds.max.z) * 0.5 * scale

	// DrawModelEx rotates around the model's exported origin. Rotate the offset from
	// that origin to the footprint center as well, so every facing stays centered.
	radians := rotation * math.PI / 180
	sin_rotation := f32(math.sin(radians))
	cos_rotation := f32(math.cos(radians))
	rotated_center_x := model_center_x * cos_rotation + model_center_z * sin_rotation
	rotated_center_z := -model_center_x * sin_rotation + model_center_z * cos_rotation

	position := helpers.coordinate_to_world(transform, entity.coordinate)
	position.x -= rotated_center_x
	position.z -= rotated_center_z
	position.y =
		static_level.FLAT_BASE_THICKNESS +
		f32(entity.bottom_half_steps) * transform.height_unit * 0.5 -
		bounds.min.y * scale

	// Gorker contains mirrored meshes (including the second eye), and all of its
	// glTF materials are marked double-sided. Raylib does not apply that flag.
	rlgl.DisableBackfaceCulling()
	defer rlgl.EnableBackfaceCulling()

	rl.DrawModelEx(
		renderer.model,
		position,
		rl.Vector3{0, 1, 0},
		rotation,
		rl.Vector3{scale, scale, scale},
		rl.WHITE,
	)
}

direction_rotation :: proc(direction: rules.Direction) -> f32 {
	switch direction {
	case .North:
		return 90
	case .East:
		return 0
	case .South:
		return -90
	case .West:
		return 180
	}

	return 0
}
