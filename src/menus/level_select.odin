package menus

import "base:runtime"
import "core:strings"
import rl "vendor:raylib"

LEVEL_BUTTON_WIDTH :: 180
LEVEL_BUTTON_HEIGHT :: 44
LEVEL_BUTTON_GAP_X :: 10
LEVEL_BUTTON_GAP_Y :: 10
LEVEL_BUTTON_MARGIN_X :: 32
LEVEL_BUTTON_START_Y :: 110

pretty_name :: proc(name: string) -> string {
	name_without_extension := strings.trim_suffix(name, ".json")
	if dash := strings.index_byte(name_without_extension, '-'); dash >= 0 {
		return name_without_extension[dash + 1:]
	}
	return name_without_extension
}

level_select :: proc(levels: ^[]runtime.Load_Directory_File) -> int {
	screen_width := int(rl.GetScreenWidth())
	available_width := max(screen_width - LEVEL_BUTTON_MARGIN_X * 2, LEVEL_BUTTON_WIDTH)
	column_count := max(
		1,
		(available_width + LEVEL_BUTTON_GAP_X) / (LEVEL_BUTTON_WIDTH + LEVEL_BUTTON_GAP_X),
	)
	row_width := min(len(levels^), column_count) * (LEVEL_BUTTON_WIDTH + LEVEL_BUTTON_GAP_X) - LEVEL_BUTTON_GAP_X
	start_x := (screen_width - row_width) / 2

	for level, i in levels^ {
		display_name := pretty_name(level.name)
		name := strings.clone_to_cstring(display_name)
		defer delete(name)
		column := i % column_count
		row := i / column_count
		bounds := rl.Rectangle{
			f32(start_x + column * (LEVEL_BUTTON_WIDTH + LEVEL_BUTTON_GAP_X)),
			f32(LEVEL_BUTTON_START_Y + row * (LEVEL_BUTTON_HEIGHT + LEVEL_BUTTON_GAP_Y)),
			LEVEL_BUTTON_WIDTH,
			LEVEL_BUTTON_HEIGHT,
		}
		if rl.GuiButton(bounds, name) {
			return i
		}
	}

	return -1
}
