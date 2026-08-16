package object_renderer

import rules "../../game_rules"
import helpers "../helpers"
import rl "vendor:raylib"

BARREL_MODEL_PATH :: "assets/Barrel.glb"
BARREL_FOOTPRINT_RATIO :: f32(0.8)

Barrel_Renderer :: struct {
	model:         rl.Model,
	model_bounds:  rl.BoundingBox,
	model_shaders: []rl.Shader,
	model_loaded:  bool,
}

barrel_init :: proc(renderer: ^Barrel_Renderer) {
	renderer.model = rl.LoadModel(BARREL_MODEL_PATH)
	renderer.model_loaded = rl.IsModelValid(renderer.model)
	if renderer.model_loaded {
		renderer.model_bounds = rl.GetModelBoundingBox(renderer.model)
		renderer.model_shaders = make([]rl.Shader, int(renderer.model.materialCount))
		for material_index in 0 ..< int(renderer.model.materialCount) {
			renderer.model_shaders[material_index] =
				renderer.model.materials[material_index].shader
		}
	}
}

barrel_unload :: proc(renderer: ^Barrel_Renderer) {
	if renderer.model_loaded {
		rl.UnloadModel(renderer.model)
	}
	delete(renderer.model_shaders)
	renderer.model_loaded = false
}

barrel_set_shader :: proc(renderer: ^Barrel_Renderer, shader: rl.Shader) {
	if !renderer.model_loaded {
		return
	}

	for material_index in 0 ..< int(renderer.model.materialCount) {
		renderer.model.materials[material_index].shader = shader
	}
}

barrel_restore_model_shaders :: proc(renderer: ^Barrel_Renderer) {
	if !renderer.model_loaded {
		return
	}

	for material_index in 0 ..< int(renderer.model.materialCount) {
		renderer.model.materials[material_index].shader = renderer.model_shaders[material_index]
	}
}

draw_barrel :: proc(renderer: ^Barrel_Renderer, barrel: rules.Entity, frame: ^helpers.Frame) {
	if !renderer.model_loaded {
		return
	}

	bounds := renderer.model_bounds
	model_width := bounds.max.x - bounds.min.x
	model_depth := bounds.max.z - bounds.min.z
	model_footprint := max(model_width, model_depth)
	if model_footprint <= 0 {
		return
	}

	scale := frame.transform.tile_size * BARREL_FOOTPRINT_RATIO / model_footprint
	position := helpers.entity_bottom_to_world(
		frame.transform,
		barrel.coordinate,
		barrel.bottom_half_steps,
	)
	if pose, found := frame.poses[barrel.id]; found {
		position = pose.position
	}
	position.y -= bounds.min.y * scale

	rl.DrawModelEx(
		renderer.model,
		position,
		rl.Vector3{0, 1, 0},
		0,
		rl.Vector3{scale, scale, scale},
		rl.WHITE,
	)
}
