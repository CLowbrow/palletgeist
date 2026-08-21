package world_renderer

import "core:c"
import "core:log"
import rl "vendor:raylib"

PALETTE_FRAGMENT_SHADER_PATH :: "assets/shaders/resurrect_64.fs"
SOFT_UPSCALE_FRAGMENT_SHADER_PATH :: "assets/shaders/soft_pixel_upscale.fs"
WEB_PALETTE_FRAGMENT_SHADER_PATH :: "assets/shaders/web/resurrect_64.fs"
WEB_SOFT_UPSCALE_FRAGMENT_SHADER_PATH :: "assets/shaders/web/soft_pixel_upscale.fs"
MAX_SCENE_DIMENSION :: c.int(720)

Post_Process :: struct {
	scene_target:        rl.RenderTexture2D,
	palette_target:      rl.RenderTexture2D,
	palette_shader:      rl.Shader,
	soft_upscale_shader: rl.Shader,
	upscale_source_size_location: c.int,
	upscale_output_size_location: c.int,
	width:               c.int,
	height:              c.int,
}

init_post_process :: proc(post: ^Post_Process) {
	when ODIN_OS == .JS {
		post.palette_shader = rl.LoadShader(nil, WEB_PALETTE_FRAGMENT_SHADER_PATH)
		post.soft_upscale_shader = rl.LoadShader(nil, WEB_SOFT_UPSCALE_FRAGMENT_SHADER_PATH)
	} else {
		post.palette_shader = rl.LoadShader(nil, PALETTE_FRAGMENT_SHADER_PATH)
		post.soft_upscale_shader = rl.LoadShader(nil, SOFT_UPSCALE_FRAGMENT_SHADER_PATH)
	}
	if !rl.IsShaderValid(post.palette_shader) {
		log.error(
			"Could not load the Resurrect 64 post-process shader; rendering the world directly",
		)
	}

	if !rl.IsShaderValid(post.soft_upscale_shader) {
		log.error(
			"Could not load the soft pixel upscale shader; presenting with bilinear filtering",
		)
	} else {
		when ODIN_OS == .JS {
			post.upscale_source_size_location =
				rl.GetShaderLocation(post.soft_upscale_shader, "sourceSize")
			post.upscale_output_size_location =
				rl.GetShaderLocation(post.soft_upscale_shader, "outputSize")
		}
	}
}

unload_post_process :: proc(post: ^Post_Process) {
	if rl.IsRenderTextureValid(post.palette_target) {
		rl.UnloadRenderTexture(post.palette_target)
	}
	if rl.IsRenderTextureValid(post.scene_target) {
		rl.UnloadRenderTexture(post.scene_target)
	}
	if rl.IsShaderValid(post.palette_shader) {
		rl.UnloadShader(post.palette_shader)
	}
	if rl.IsShaderValid(post.soft_upscale_shader) {
		rl.UnloadShader(post.soft_upscale_shader)
	}
	post^ = {}
}

prepare_post_process :: proc(post: ^Post_Process) -> bool {
	if !rl.IsShaderValid(post.palette_shader) {
		return false
	}

	width, height := capped_scene_size(rl.GetScreenWidth(), rl.GetScreenHeight())
	if width <= 0 || height <= 0 {
		return false
	}
	if width == post.width &&
	   height == post.height &&
	   rl.IsRenderTextureValid(post.scene_target) &&
	   rl.IsRenderTextureValid(post.palette_target) {
		return true
	}

	new_scene := rl.LoadRenderTexture(width, height)
	new_palette := rl.LoadRenderTexture(width, height)
	if !rl.IsRenderTextureValid(new_scene) || !rl.IsRenderTextureValid(new_palette) {
		if rl.IsRenderTextureValid(new_palette) {
			rl.UnloadRenderTexture(new_palette)
		}
		if rl.IsRenderTextureValid(new_scene) {
			rl.UnloadRenderTexture(new_scene)
		}
		log.errorf(
			"Could not create %dx%d world post-process targets; rendering the world directly",
			width,
			height,
		)
		return false
	}

	if rl.IsRenderTextureValid(post.palette_target) {
		rl.UnloadRenderTexture(post.palette_target)
	}
	if rl.IsRenderTextureValid(post.scene_target) {
		rl.UnloadRenderTexture(post.scene_target)
	}

	post.scene_target = new_scene
	post.palette_target = new_palette
	post.width = width
	post.height = height
	// The upscale shader warps bilinear sampling so only the narrow boundary
	// between source pixels is blended; the center of each pixel stays solid.
	rl.SetTextureFilter(post.palette_target.texture, .BILINEAR)
	return true
}

capped_scene_size :: proc(window_width, window_height: c.int) -> (width, height: c.int) {
	if window_width <= 0 || window_height <= 0 {
		return
	}

	largest_dimension := max(window_width, window_height)
	if largest_dimension <= MAX_SCENE_DIMENSION {
		return window_width, window_height
	}

	if window_width >= window_height {
		width = MAX_SCENE_DIMENSION
		height = max(
			c.int(f32(window_height) * f32(MAX_SCENE_DIMENSION) / f32(window_width) + 0.5),
			1,
		)
	} else {
		height = MAX_SCENE_DIMENSION
		width = max(
			c.int(f32(window_width) * f32(MAX_SCENE_DIMENSION) / f32(window_height) + 0.5),
			1,
		)
	}
	return
}

begin_scene_pass :: proc(post: ^Post_Process) {
	rl.BeginTextureMode(post.scene_target)
}

end_scene_pass_and_present :: proc(post: ^Post_Process) {
	rl.EndTextureMode()

	source := rl.Rectangle{0, 0, f32(post.width), -f32(post.height)}
	target := rl.Rectangle{0, 0, f32(post.width), f32(post.height)}
	rl.BeginTextureMode(post.palette_target)
	rl.ClearBackground(rl.BLANK)
	rl.BeginShaderMode(post.palette_shader)
	rl.DrawTexturePro(post.scene_target.texture, source, target, {}, 0, rl.WHITE)
	rl.EndShaderMode()
	rl.EndTextureMode()

	window_target := rl.Rectangle{0, 0, f32(rl.GetScreenWidth()), f32(rl.GetScreenHeight())}
	if rl.IsShaderValid(post.soft_upscale_shader) {
		when ODIN_OS == .JS {
			source_size := rl.Vector2{f32(post.width), f32(post.height)}
			output_size := rl.Vector2{f32(rl.GetScreenWidth()), f32(rl.GetScreenHeight())}
			rl.SetShaderValue(
				post.soft_upscale_shader,
				post.upscale_source_size_location,
				&source_size,
				.VEC2,
			)
			rl.SetShaderValue(
				post.soft_upscale_shader,
				post.upscale_output_size_location,
				&output_size,
				.VEC2,
			)
		}
		rl.BeginShaderMode(post.soft_upscale_shader)
	}
	rl.DrawTexturePro(post.palette_target.texture, source, window_target, {}, 0, rl.WHITE)
	if rl.IsShaderValid(post.soft_upscale_shader) {
		rl.EndShaderMode()
	}
}
