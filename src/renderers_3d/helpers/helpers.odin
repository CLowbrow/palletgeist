package helpers

import rules "../../game_rules"
import "core:mem"
import rl "vendor:raylib"

BASE_THICKNESS :: f32(0.12)

UI_Mode :: enum {
	MainMenu,
	PauseMenu,
	LevelWon,
	LevelLost,
	Playing,
	LevelSelect,
	Animating,
}

SortedObjects :: struct {
	player:  rules.Entity,
	boxes:   [dynamic]rules.Entity,
	barrels: [dynamic]rules.Entity,
}

Grid_Transform :: struct {
	coordinates: rules.Coordinate_System,
	tile_size:   f32,
	height_unit: f32,
}

coordinate_to_world :: proc(
	transform: ^Grid_Transform,
	coordinate: rules.Coordinate,
) -> rl.Vector3 {
	dx := f32(coordinate.x - transform.coordinates.origin.x)
	dy := f32(coordinate.y - transform.coordinates.origin.y)

	x_sign: f32 = 1
	z_sign: f32 = -1

	return rl.Vector3{dx * x_sign * transform.tile_size, 0, dy * z_sign * transform.tile_size}
}
