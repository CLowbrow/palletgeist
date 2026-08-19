package object_renderer

import rules "../../game_rules"
import helpers "../helpers"
import rl "vendor:raylib"

BARREL_MODEL_PATH :: "assets/Barrel.glb"
BARREL_DAMAGED_MODEL_PATH :: "assets/Barrel_Damaged.glb"
BARREL_FOOTPRINT_RATIO :: f32(0.8)

Barrel_Model :: struct {
	model:         rl.Model,
	model_bounds:  rl.BoundingBox,
	model_shaders: []rl.Shader,
	model_loaded:  bool,
}

Barrel_Renderer :: struct {
	normal:  Barrel_Model,
	damaged: Barrel_Model,
}

barrel_model_init :: proc(asset: ^Barrel_Model, path: cstring) {
	asset.model = rl.LoadModel(path)
	asset.model_loaded = rl.IsModelValid(asset.model)
	if asset.model_loaded {
		asset.model_bounds = rl.GetModelBoundingBox(asset.model)
		asset.model_shaders = make([]rl.Shader, int(asset.model.materialCount))
		for material_index in 0 ..< int(asset.model.materialCount) {
			asset.model_shaders[material_index] = asset.model.materials[material_index].shader
		}
	}
}

barrel_init :: proc(renderer: ^Barrel_Renderer) {
	barrel_model_init(&renderer.normal, BARREL_MODEL_PATH)
	barrel_model_init(&renderer.damaged, BARREL_DAMAGED_MODEL_PATH)
}

barrel_model_unload :: proc(asset: ^Barrel_Model) {
	if asset.model_loaded {
		rl.UnloadModel(asset.model)
	}
	delete(asset.model_shaders)
	asset.model_loaded = false
}

barrel_unload :: proc(renderer: ^Barrel_Renderer) {
	barrel_model_unload(&renderer.normal)
	barrel_model_unload(&renderer.damaged)
}

barrel_model_set_shader :: proc(asset: ^Barrel_Model, shader: rl.Shader) {
	if !asset.model_loaded {
		return
	}

	for material_index in 0 ..< int(asset.model.materialCount) {
		asset.model.materials[material_index].shader = shader
	}
}

barrel_set_shader :: proc(renderer: ^Barrel_Renderer, shader: rl.Shader) {
	barrel_model_set_shader(&renderer.normal, shader)
	barrel_model_set_shader(&renderer.damaged, shader)
}

barrel_model_restore_shaders :: proc(asset: ^Barrel_Model) {
	if !asset.model_loaded {
		return
	}

	for material_index in 0 ..< int(asset.model.materialCount) {
		asset.model.materials[material_index].shader = asset.model_shaders[material_index]
	}
}

barrel_restore_model_shaders :: proc(renderer: ^Barrel_Renderer) {
	barrel_model_restore_shaders(&renderer.normal)
	barrel_model_restore_shaders(&renderer.damaged)
}

barrel_is_armed :: proc(state: ^rules.Resolved_State, id: u64) -> bool {
	for armed_id in rules.armed_barrel_ids_view(state) {
		if armed_id == id {
			return true
		}
	}
	return false
}

draw_barrel :: proc(renderer: ^Barrel_Renderer, barrel: rules.Entity, frame: ^helpers.Frame) {
	asset := &renderer.normal
	rotation: f32
	armed_before := barrel_is_armed(frame.state_before, barrel.id)
	armed_after := barrel_is_armed(frame.state_after, barrel.id)
	if (armed_before || armed_after) && renderer.damaged.model_loaded {
		asset = &renderer.damaged
		rotation = 0
	}
	if !asset.model_loaded {
		return
	}

	bounds := asset.model_bounds
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
		asset.model,
		position,
		rl.Vector3{0, 1, 0},
		rotation,
		rl.Vector3{scale, scale, scale},
		rl.WHITE,
	)
}
