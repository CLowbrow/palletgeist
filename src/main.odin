package main

import "core:fmt"
import rl "vendor:raylib"

import "core:log"
import rules "game_rules"
import model "game_state"
import helpers "helpers"
import menus "menus"
import world "renderers_3d/world_renderer"

WINDOW_WIDTH :: 1280
WINDOW_HEIGHT :: 720
WINDOW_TITLE :: "Palletgeist"
MIN_WINDOW_WIDTH :: 640
MIN_WINDOW_HEIGHT :: 360

EMBEDDED_LEVELS := #load_directory("../levels")

Game_State :: struct {
	engine:          rules.Engine,
	current_level:   int,
	world_state:     model.World_State,
	world_renderer:  world.Renderer,
	mode:            helpers.UI_Mode,
	animation_queue: helpers.Turn_Animation_Queue,
	// populated by the rules engine and retained until the next move
	retained_result: rules.Move_Result,
	won_time:        f64,
}

App :: struct {
	game:              Game_State,
	engine_created:    bool,
	window_initialized: bool,
	world_initialized: bool,
	ready:              bool,
}

app_init :: proc(app: ^App) -> bool {
	// Bootstrap the platform-neutral game state before creating GPU resources.
	engine, engine_created := rules.create_engine()
	app.game = {
		mode     = helpers.UI_Mode.MainMenu,
		engine   = engine,
		won_time = 1,
	}
	app.engine_created = engine_created

	if !rules.api_is_compatible() {
		fmt.eprintln("Unsupported game-rules C API version")
		return false
	}
	if !engine_created {
		fmt.eprintln("Could not create the game-rules engine")
		return false
	}

	rl.SetConfigFlags({.WINDOW_RESIZABLE})
	rl.InitWindow(WINDOW_WIDTH, WINDOW_HEIGHT, WINDOW_TITLE)
	app.window_initialized = rl.IsWindowReady()
	if !app.window_initialized {
		fmt.eprintln("Could not initialize the game window")
		return false
	}
	when ODIN_OS != .JS {
		rl.SetWindowMinSize(MIN_WINDOW_WIDTH, MIN_WINDOW_HEIGHT)
	}

	world.init(&app.game.world_renderer)
	app.world_initialized = true

	if !start_level(&app.game, 0) {
		fmt.eprintln("Could not load initial level")
		return false
	}

	// Browser frames are driven by requestAnimationFrame. SetTargetFPS makes
	// raylib call emscripten_sleep from EndDrawing, which requires Asyncify.
	when ODIN_OS != .JS {
		rl.SetTargetFPS(60)
	}
	app.ready = true
	return true
}

app_frame :: proc(app: ^App) -> bool {
	if !app.ready || !app.window_initialized {
		return false
	}
	// raylib's web implementation of WindowShouldClose sleeps to emulate a
	// synchronous loop. The browser entry point already owns the async loop.
	when ODIN_OS != .JS {
		if rl.WindowShouldClose() {
			return false
		}
	}
	update(&app.game)
	draw(&app.game)
	return true
}

app_shutdown :: proc(app: ^App) {
	if app == nil {
		return
	}

	rules.dispose_move_result(&app.game.retained_result)
	model.unload(&app.game.world_state)
	if app.world_initialized {
		world.unload(&app.game.world_renderer)
	}
	if app.window_initialized {
		rl.CloseWindow()
	}
	if app.engine_created {
		rules.destroy_engine(&app.game.engine)
	}
	app^ = {}
}

when ODIN_OS != .JS {
	main :: proc() {
		context.logger = log.create_console_logger()
		defer log.destroy_console_logger(context.logger)

		app: App
		defer app_shutdown(&app)
		if !app_init(&app) {
			return
		}

		for app_frame(&app) {}
	}
}

update :: proc(game: ^Game_State) {
	update_move_animation(game, rl.GetFrameTime())

	if game.won_time != 0 && rl.GetTime() - game.won_time > 3 && game.mode == .LevelWon {
		log.debug("Won game")
		game.won_time = 0

		if game.current_level == len(EMBEDDED_LEVELS) - 1 {
			return
		}

		if !start_level(game, game.current_level + 1) {
			log.errorf("Could not reset level")
		}
		game.mode = .Playing
		return
	}

	// Handle input
	if game.mode == helpers.UI_Mode.Playing && !game.animation_queue.animating {
		if rl.IsKeyPressed(.LEFT) {
			apply_move(game, .West)
		} else if rl.IsKeyPressed(.RIGHT) {
			apply_move(game, .East)
		} else if rl.IsKeyPressed(.UP) {
			apply_move(game, .North)
		} else if rl.IsKeyPressed(.DOWN) {
			apply_move(game, .South)
		}

		if rl.IsKeyPressed(.R) {
			// Reset level
			if !start_level(game, game.current_level) {
				log.errorf("Could not reset level")
				return
			}
		}
		if rl.IsKeyPressed(.Z) {
			// Undo one move
			apply_rewind(game)
		}
	}
}

draw :: proc(game: ^Game_State) {
	rl.BeginDrawing()
	defer rl.EndDrawing()

	rl.ClearBackground(rl.Color{20, 22, 28, 255})
	world.draw(&game.world_renderer, &game.world_state, &game.animation_queue, game.mode)

	if game.mode == .MainMenu {
		if game.mode == .MainMenu {
			switch menus.main_menu() {
			case .Play:
				game.mode = .Playing
				break
			case .None:
				break
			case .Quit:
				rl.CloseWindow()
				break
			case .SelectLevel:
				game.mode = .LevelSelect
				break
			}
		}
	} else if game.mode == .LevelSelect {
		if selected_level := menus.level_select(&EMBEDDED_LEVELS); selected_level >= 0 {
			if start_level(game, selected_level) {
				game.mode = .Playing
			}

		}
	}

	if game.mode != .Playing {
		rl.DrawText("Palletgeist", 48, 44, 40, rl.RAYWHITE)
	} else {
		if rl.GuiButton(rl.Rectangle{48, 44, 40, 44}, "Menu") {
			game.mode = .MainMenu
		}
	}

	//rl.DrawFPS(50, WINDOW_HEIGHT - 38)
}
