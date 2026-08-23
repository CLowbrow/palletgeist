// Package explosion_renderer draws short-lived expanding spheres for barrel explosions.
package explosion_renderer

import rules "../../game_rules"
import project "../../helpers"
import helpers "../helpers"
import "core:c"
import "core:log"
import "core:math"
import rl "vendor:raylib"
import rlgl "vendor:raylib/rlgl"

VERTEX_SHADER_PATH :: "assets/shaders/explosion.vs"
FRAGMENT_SHADER_PATH :: "assets/shaders/explosion.fs"
SOUND_PATH :: "assets/sfx/bomb.wav"
SPHERE_RADIUS :: f32(0.5)
SPHERE_RINGS :: 16
SPHERE_SLICES :: 24
START_SCALE :: f32(0.12)
END_SCALE :: f32(2.4)
START_OPACITY :: f32(0.92)
OPACITY_FALLOFF :: f32(0.65)

Renderer :: struct {
	positions:         [dynamic]rl.Vector3,
	active_tick:       ^rules.Tick,
	model:             rl.Model,
	shader:            rl.Shader,
	progress_location: c.int,
	opacity_location:  c.int,
	model_loaded:      bool,
	sound:             rl.Sound,
	sound_loaded:      bool,
}

init :: proc(renderer: ^Renderer) {
	renderer.positions = make([dynamic]rl.Vector3, 0, 4)
	if rl.IsAudioDeviceReady() {
		renderer.sound = rl.LoadSound(SOUND_PATH)
		renderer.sound_loaded = rl.IsSoundValid(renderer.sound)
		if !renderer.sound_loaded {
			log.error("Could not load the explosion sound")
		}
	} else {
		log.error("Could not initialize audio for the explosion sound")
	}
}

unload :: proc(renderer: ^Renderer) {
	reset(renderer)
	if renderer.sound_loaded {
		rl.UnloadSound(renderer.sound)
	}
	delete(renderer.positions)
	renderer^ = {}
}

// reset releases the per-animation GPU resources. Nothing is retained between
// explosion ticks because these effects are deliberately temporary.
reset :: proc(renderer: ^Renderer) {
	if renderer == nil {
		return
	}

	if renderer.model_loaded {
		rl.UnloadModel(renderer.model)
	}
	if rl.IsShaderValid(renderer.shader) {
		rl.UnloadShader(renderer.shader)
	}

	clear(&renderer.positions)
	renderer.active_tick = nil
	renderer.model = {}
	renderer.shader = {}
	renderer.progress_location = 0
	renderer.opacity_location = 0
	renderer.model_loaded = false
}

// sync starts a new group of effects when the animation enters an explosion
// tick and tears the previous group's assets down when that tick ends.
sync :: proc(
	renderer: ^Renderer,
	tick: ^rules.Tick,
	transform: ^helpers.Grid_Transform,
) {
	if renderer == nil || transform == nil || renderer.active_tick == tick {
		return
	}

	reset(renderer)
	renderer.active_tick = tick
	if tick == nil {
		return
	}

	for event in project.events_view(tick) {
		if event.kind != .Barrel_Exploded {
			continue
		}

		position := helpers.coordinate_to_world(transform, event.coordinate)
		position.y =
			helpers.BASE_THICKNESS +
			f32(event.bottom_half_steps) * transform.height_unit * 0.5 +
			transform.height_unit * 0.5
		append(&renderer.positions, position)
	}

	if len(renderer.positions) == 0 {
		return
	}
	if renderer.sound_loaded {
		rl.PlaySound(renderer.sound)
	}

	mesh := rl.GenMeshSphere(SPHERE_RADIUS, SPHERE_RINGS, SPHERE_SLICES)
	renderer.model = rl.LoadModelFromMesh(mesh)
	renderer.model_loaded = rl.IsModelValid(renderer.model)
	if !renderer.model_loaded {
		log.error("Could not create the temporary explosion sphere")
		return
	}

	renderer.shader = rl.LoadShader(VERTEX_SHADER_PATH, FRAGMENT_SHADER_PATH)
	if !rl.IsShaderValid(renderer.shader) {
		log.error("Could not load the explosion shader; using normal rendering")
		return
	}

	renderer.progress_location = rl.GetShaderLocation(renderer.shader, "progress")
	renderer.opacity_location = rl.GetShaderLocation(renderer.shader, "opacity")
	renderer.model.materials[0].shader = renderer.shader
}

draw :: proc(renderer: ^Renderer, progress: f32, tile_size: f32) {
	if renderer == nil || !renderer.model_loaded || len(renderer.positions) == 0 {
		return
	}

	t := clamp(progress, f32(0), f32(1))
	one_minus_t := 1 - t
	expansion := 1 - one_minus_t * one_minus_t * one_minus_t
	scale := (START_SCALE + (END_SCALE - START_SCALE) * expansion) * tile_size
	opacity := START_OPACITY * math.pow_f32(one_minus_t, OPACITY_FALLOFF)

	using_shader := rl.IsShaderValid(renderer.shader)
	if using_shader {
		rl.SetShaderValue(renderer.shader, renderer.progress_location, &t, .FLOAT)
		rl.SetShaderValue(renderer.shader, renderer.opacity_location, &opacity, .FLOAT)
	}

	// The source effect is additive and does not write depth. Keeping the same
	// blend behavior makes the simple solid sphere read as a brief flash.
	rlgl.DrawRenderBatchActive()
	rlgl.DisableDepthMask()
	rl.BeginBlendMode(.ADDITIVE)

	tint := rl.Color{255, 122, 24, u8(opacity * 255)}
	if using_shader {
		tint = rl.WHITE
	}
	for position in renderer.positions {
		rl.DrawModelEx(
			renderer.model,
			position,
			rl.Vector3{0, 1, 0},
			0,
			rl.Vector3{scale, scale, scale},
			tint,
		)
	}

	rl.EndBlendMode()
	rlgl.DrawRenderBatchActive()
	rlgl.EnableDepthMask()
}
