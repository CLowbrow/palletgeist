package main

import "core:fmt"
import rl "vendor:raylib"

import rules "game_rules"

WINDOW_WIDTH  :: 1280
WINDOW_HEIGHT :: 720
WINDOW_TITLE  :: "Palletgeist"

main :: proc() {
	engine, engine_created := rules.create_engine()
	if !engine_created {
		fmt.eprintln("Could not create the game-rules engine")
		return
	}
	defer rules.destroy_engine(&engine)

	if !rules.api_is_compatible() {
		fmt.eprintln("Unsupported game-rules C API version")
		return
	}

	fmt.printf("Game rules: %s (data API v%d)\n", rules.status(), rules.data_api_version())

	rl.InitWindow(WINDOW_WIDTH, WINDOW_HEIGHT, WINDOW_TITLE)
	defer rl.CloseWindow()

	rl.SetTargetFPS(60)

	for !rl.WindowShouldClose() {
		update()
		draw()
	}
}

update :: proc() {
	// Put game here
}

draw :: proc() {
	rl.BeginDrawing()
	defer rl.EndDrawing()

	rl.ClearBackground(rl.Color{20, 22, 28, 255})
	rl.DrawText("Palletgeist", 48, 44, 40, rl.RAYWHITE)
	rl.DrawFPS(50, WINDOW_HEIGHT - 38)
}

