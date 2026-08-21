package world_renderer

import "core:c"
import "core:log"
import rl "vendor:raylib"
import rlgl "vendor:raylib/rlgl"

SHADOW_VERTEX_SHADER_PATH :: "assets/shaders/shadowmap.vs"
SHADOW_FRAGMENT_SHADER_PATH :: "assets/shaders/shadowmap.fs"
WEB_SHADOW_VERTEX_SHADER_PATH :: "assets/shaders/web/shadowmap.vs"
WEB_SHADOW_FRAGMENT_SHADER_PATH :: "assets/shaders/web/shadowmap.fs"
SHADOW_MAP_RESOLUTION :: 1080
SHADOW_TEXTURE_SLOT :: 10
WEB_SHADOW_TEXTURE_SLOT :: 1
MIN_LIGHT_VIEW_SPAN :: f32(6)
LIGHT_VIEW_PADDING :: f32(3)

Lighting :: struct {
	shader:                         rl.Shader,
	shadow_map:                     rl.RenderTexture2D,
	light_camera:                   rl.Camera3D,
	light_direction:                rl.Vector3,
	light_view:                     rl.Matrix,
	light_projection:               rl.Matrix,
	light_view_projection:          rl.Matrix,
	light_view_projection_location: c.int,
	shadow_map_location:            c.int,
	ready:                          bool,
}

init_lighting :: proc(lighting: ^Lighting) {
	when ODIN_OS == .JS {
		lighting.shader = rl.LoadShader(
			WEB_SHADOW_VERTEX_SHADER_PATH,
			WEB_SHADOW_FRAGMENT_SHADER_PATH,
		)
	} else {
		lighting.shader = rl.LoadShader(SHADOW_VERTEX_SHADER_PATH, SHADOW_FRAGMENT_SHADER_PATH)
	}
	if !rl.IsShaderValid(lighting.shader) {
		log.error("Could not load the world lighting shader; using unlit rendering")
		return
	}

	lighting.light_view_projection_location = rl.GetShaderLocation(lighting.shader, "lightVP")
	lighting.shadow_map_location = rl.GetShaderLocation(lighting.shader, "shadowMap")

	lighting.light_direction = rl.Vector3Normalize(rl.Vector3{0.45, -1.0, -0.35})
	light_color := rl.Vector4{1.0, 0.94, 0.82, 1.0}
	ambient := rl.Vector4{0.26, 0.29, 0.36, 1.0}
	resolution: c.int = SHADOW_MAP_RESOLUTION

	set_shader_value(lighting, "lightDir", &lighting.light_direction, .VEC3)
	set_shader_value(lighting, "lightColor", &light_color, .VEC4)
	set_shader_value(lighting, "ambient", &ambient, .VEC4)
	set_shader_value(lighting, "shadowMapResolution", &resolution, .INT)

	lighting.shadow_map, lighting.ready = load_shadow_map(SHADOW_MAP_RESOLUTION)
	if !lighting.ready {
		log.error("Could not create the shadow map; using unlit rendering")
	}
}

unload_lighting :: proc(lighting: ^Lighting) {
	if lighting.shadow_map.id != 0 {
		unload_shadow_map(lighting.shadow_map)
	}
	if rl.IsShaderValid(lighting.shader) {
		rl.UnloadShader(lighting.shader)
	}
	lighting^ = {}
}

fit_light_to_bounds :: proc(lighting: ^Lighting, bounds: rl.BoundingBox) {
	center := rl.Vector3 {
		(bounds.min.x + bounds.max.x) * 0.5,
		(bounds.min.y + bounds.max.y) * 0.5,
		(bounds.min.z + bounds.max.z) * 0.5,
	}
	extent_x := bounds.max.x - bounds.min.x
	extent_y := bounds.max.y - bounds.min.y
	extent_z := bounds.max.z - bounds.min.z
	view_span := max(extent_x + extent_z + extent_y + LIGHT_VIEW_PADDING, MIN_LIGHT_VIEW_SPAN)
	distance := view_span * 1.5

	lighting.light_camera = rl.Camera3D {
		position   = center - lighting.light_direction * distance,
		target     = center,
		up         = {0, 1, 0},
		fovy       = view_span,
		projection = .ORTHOGRAPHIC,
	}
}

begin_shadow_pass :: proc(lighting: ^Lighting) {
	rl.BeginTextureMode(lighting.shadow_map)
	rl.ClearBackground(rl.WHITE)
	rl.BeginMode3D(lighting.light_camera)
	lighting.light_view = rlgl.GetMatrixModelview()
	lighting.light_projection = rlgl.GetMatrixProjection()
}

end_shadow_pass :: proc(lighting: ^Lighting) {
	rl.EndMode3D()
	rl.EndTextureMode()
	lighting.light_view_projection = lighting.light_projection * lighting.light_view
}

begin_lit_pass :: proc(lighting: ^Lighting) {
	rl.SetShaderValueMatrix(
		lighting.shader,
		lighting.light_view_projection_location,
		lighting.light_view_projection,
	)
	rl.BeginShaderMode(lighting.shader)
	// Low-level uniforms apply to the currently bound GPU program. BeginShaderMode
	// selects the shader for raylib's next batch, so activate it explicitly before
	// assigning the manually bound shadow-map texture unit, as the raylib example does.
	rlgl.EnableShader(lighting.shader.id)
	texture_slot: c.int
	when ODIN_OS == .JS {
		// WebGL 1 only guarantees eight fragment texture units. Unit one is free
		// alongside the model's texture0 and works on every conforming browser.
		texture_slot = WEB_SHADOW_TEXTURE_SLOT
	} else {
		texture_slot = SHADOW_TEXTURE_SLOT
	}
	rlgl.ActiveTextureSlot(texture_slot)
	rlgl.EnableTexture(lighting.shadow_map.depth.id)
	rlgl.SetUniform(
		lighting.shadow_map_location,
		&texture_slot,
		c.int(rl.ShaderUniformDataType.INT),
		1,
	)
}

end_lit_pass :: proc(lighting: ^Lighting) {
	rl.EndShaderMode()
	when ODIN_OS == .JS {
		rlgl.ActiveTextureSlot(WEB_SHADOW_TEXTURE_SLOT)
	} else {
		rlgl.ActiveTextureSlot(SHADOW_TEXTURE_SLOT)
	}
	rlgl.DisableTexture()
	rlgl.ActiveTextureSlot(0)
}

set_shader_value :: proc(
	lighting: ^Lighting,
	name: cstring,
	value: rawptr,
	value_type: rl.ShaderUniformDataType,
) {
	location := rl.GetShaderLocation(lighting.shader, name)
	rl.SetShaderValue(lighting.shader, location, value, value_type)
}

load_shadow_map :: proc(resolution: c.int) -> (target: rl.RenderTexture2D, ok: bool) {
	target.id = rlgl.LoadFramebuffer()
	if target.id == 0 {
		return
	}

	target.texture.width = resolution
	target.texture.height = resolution
	target.depth.width = resolution
	target.depth.height = resolution
	target.depth.mipmaps = 1

	rlgl.EnableFramebuffer(target.id)
	target.depth.id = rlgl.LoadTextureDepth(resolution, resolution, false)
	if target.depth.id != 0 {
		rlgl.FramebufferAttach(
			target.id,
			target.depth.id,
			c.int(rlgl.FramebufferAttachType.DEPTH),
			c.int(rlgl.FramebufferAttachTextureType.TEXTURE2D),
			0,
		)
		ok = rlgl.FramebufferComplete(target.id)
	}
	rlgl.DisableFramebuffer()

	if ok {
		rl.SetTextureFilter(target.depth, .POINT)
		rl.SetTextureWrap(target.depth, .CLAMP)
	}

	if !ok {
		unload_shadow_map(target)
		target = {}
	}
	return
}

unload_shadow_map :: proc(target: rl.RenderTexture2D) {
	if target.depth.id != 0 {
		rlgl.UnloadTexture(target.depth.id)
	}
	if target.id != 0 {
		rlgl.UnloadFramebuffer(target.id)
	}
}
