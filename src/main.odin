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

main :: proc() {
	context.logger = log.create_console_logger()
	defer log.destroy_console_logger(context.logger)

	// Bootstrap engine
	engine, engine_created := rules.create_engine()
	defer rules.destroy_engine(&engine)
	if !rules.api_is_compatible() {
		fmt.eprintln("Unsupported game-rules C API version")
		return
	}
	if !engine_created {
		fmt.eprintln("Could not create the game-rules engine")
		return
	}

	game := Game_State {
		mode     = helpers.UI_Mode.MainMenu,
		engine   = engine,
		won_time = 1,
	}
	defer rules.dispose_move_result(&game.retained_result)

	rl.SetConfigFlags({.WINDOW_RESIZABLE})
	rl.InitWindow(WINDOW_WIDTH, WINDOW_HEIGHT, WINDOW_TITLE)
	rl.SetWindowMinSize(MIN_WINDOW_WIDTH, MIN_WINDOW_HEIGHT)
	defer rl.CloseWindow()

	world.init(&game.world_renderer)
	defer world.unload(&game.world_renderer)
	defer model.unload(&game.world_state)

	if !start_level(&game, 0) {
		fmt.eprintln("Could not load initial level")
		return
	}

	rl.SetTargetFPS(60)

	for !rl.WindowShouldClose() {
		update(&game)
		draw(&game)
	}
}

update :: proc(game: ^Game_State) {
	update_move_animation(game, rl.GetFrameTime())

	if game.won_time != 0 && rl.GetTime() - game.won_time > 3 {
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
