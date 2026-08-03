package main

import "core:fmt"
import rl "vendor:raylib"

import rules "game_rules"

WINDOW_WIDTH :: 1280
WINDOW_HEIGHT :: 720
WINDOW_TITLE :: "Palletgeist"

EMBEDDED_LEVELS := #load_directory("../levels")

App_Mode :: enum {
	MainMenu,
	PauseMenu,
	LevelWon,
	LevelLost,
	Playing,
}

Game_State :: struct {
	engine: rules.Engine,
	mode:   App_Mode,
}

main :: proc() {
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
		mode   = App_Mode.MainMenu,
		engine = engine,
	}

	response, ok := rules.load_level_json(&game.engine, EMBEDDED_LEVELS[0].data)
	if !ok {
		fmt.eprintln("Could not load level")
		return
	}
	delete(response)

	rl.InitWindow(WINDOW_WIDTH, WINDOW_HEIGHT, WINDOW_TITLE)
	defer rl.CloseWindow()

	rl.SetTargetFPS(60)

	for !rl.WindowShouldClose() {
		update(&game)
		draw(&game)
	}
}

update :: proc(game: ^Game_State) {
	// Handle input
	if rl.IsKeyPressed(.LEFT) && game.mode == App_Mode.Playing {
		response, ok := rules.move_left(&game.engine)
		if ok {
			// TOOO: Do something
			delete(response)
		}
	}
	if rl.IsKeyPressed(.RIGHT) && game.mode == App_Mode.Playing {
		response, ok := rules.move_right(&game.engine)
		if ok {
			// TOOO: Do something
			delete(response)
		}
	}
	if rl.IsKeyPressed(.UP) {
		if game.mode == App_Mode.Playing {
			response, ok := rules.move_up(&game.engine)
			if ok {
				// TOOO: Do something
				delete(response)
			}
		} else if game.mode == App_Mode.LevelLost ||
		   game.mode == App_Mode.LevelWon ||
		   game.mode == App_Mode.MainMenu {
			// Menu Navigation
		}
	}
	if rl.IsKeyPressed(.DOWN) && game.mode == App_Mode.Playing {
		if game.mode == App_Mode.Playing {
			response, ok := rules.move_down(&game.engine)
			if ok {
				// TOOO: Do something
				delete(response)
			}
		} else if game.mode == App_Mode.LevelLost ||
		   game.mode == App_Mode.LevelWon ||
		   game.mode == App_Mode.MainMenu {
			// Menu Navigation
		}
	}

}

draw :: proc(game: ^Game_State) {
	rl.BeginDrawing()
	defer rl.EndDrawing()

	rl.ClearBackground(rl.Color{20, 22, 28, 255})
	rl.DrawText("Palletgeist", 48, 44, 40, rl.RAYWHITE)
	rl.DrawFPS(50, WINDOW_HEIGHT - 38)
}
