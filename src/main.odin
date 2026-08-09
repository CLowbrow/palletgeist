package main

import "core:fmt"
import rl "vendor:raylib"

import "core:log"
import rules "game_rules"
import menus "menus"
import world "renderers_3d/world_renderer"

WINDOW_WIDTH :: 1280
WINDOW_HEIGHT :: 720
WINDOW_TITLE :: "Palletgeist"
MIN_WINDOW_WIDTH :: 640
MIN_WINDOW_HEIGHT :: 360

EMBEDDED_LEVELS := #load_directory("../levels")

App_Mode :: enum {
	MainMenu,
	PauseMenu,
	LevelWon,
	LevelLost,
	Playing,
	LevelSelect,
	Animating,
}

Game_State :: struct {
	engine:         rules.Engine,
	world_renderer: world.Renderer,
	mode:           App_Mode,
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
		mode   = App_Mode.MainMenu,
		engine = engine,
	}

	response, ok := rules.load_level_json(&game.engine, EMBEDDED_LEVELS[0].data)
	if !ok {
		fmt.eprintln("Could not load level")
		return
	}
	delete(response)

	rl.SetConfigFlags({.WINDOW_RESIZABLE, .MSAA_4X_HINT})
	rl.InitWindow(WINDOW_WIDTH, WINDOW_HEIGHT, WINDOW_TITLE)
	rl.SetWindowMinSize(MIN_WINDOW_WIDTH, MIN_WINDOW_HEIGHT)
	defer rl.CloseWindow()

	world.init(&game.world_renderer)
	defer world.unload(&game.world_renderer)
	if !refresh_world_renderer(&game) {
		fmt.eprintln("Could not get initial level state")
		return
	}

	rl.SetTargetFPS(60)

	for !rl.WindowShouldClose() {
		update(&game)
		draw(&game)
	}
}

refresh_world_renderer :: proc(game: ^Game_State) -> bool {
	result: rules.State_Result
	call := rules.get_state(&game.engine, &result)
	defer rules.dispose_state_result(&result)
	if call != .Ok || result.has_state == 0 {
		return false
	}

	world.load_level(&game.world_renderer, &result.state)
	return true
}

apply_move :: proc(game: ^Game_State, direction: rules.Direction) {
	result: rules.Move_Result
	call := rules.move(&game.engine, direction, &result)
	defer rules.dispose_move_result(&result)
	if call != .Ok {
		log.errorf("Rules move call failed: %v", call)
		return
	}

	log.infof(
		"Move: status=%v accepted=%v ticks=%d events=%d",
		result.status,
		result.accepted != 0,
		result.tick_count,
		result.event_count,
	)

	if result.has_state != 0 {
		world.update_player(&game.world_renderer, &result.state.resolved, direction)
	}
}

update :: proc(game: ^Game_State) {
	// Handle input
	if game.mode == App_Mode.Playing {
		if rl.IsKeyPressed(.LEFT) {
			apply_move(game, .West)
		} else if rl.IsKeyPressed(.RIGHT) {
			apply_move(game, .East)
		} else if rl.IsKeyPressed(.UP) {
			apply_move(game, .North)
		} else if rl.IsKeyPressed(.DOWN) {
			apply_move(game, .South)
		}
	}
}

draw :: proc(game: ^Game_State) {
	rl.BeginDrawing()
	defer rl.EndDrawing()

	rl.ClearBackground(rl.Color{20, 22, 28, 255})

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
			response, ok := rules.load_level_json(
				&game.engine,
				EMBEDDED_LEVELS[selected_level].data,
			)
			delete(response)
			if !ok {
				fmt.eprintln("Could not load level")
				return
			}
			if !refresh_world_renderer(game) {
				fmt.eprintln("Could not get level state")
				return
			}
			game.mode = .Playing
		}
	}

	if game.mode != .Playing {
		rl.DrawText("Palletgeist", 48, 44, 40, rl.RAYWHITE)
	} else {
		if rl.GuiButton(rl.Rectangle{48, 44, 40, 44}, "Menu") {
			game.mode = .MainMenu
		}
	}

	// We always draw the level
	world.draw(&game.world_renderer)
	//rl.DrawFPS(50, WINDOW_HEIGHT - 38)
}
