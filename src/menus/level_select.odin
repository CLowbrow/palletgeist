package menus

import "base:runtime"
import "core:strings"
import rl "vendor:raylib"

pretty_name :: proc(name: string) -> string {
	name_without_extension := strings.trim_suffix(name, ".json")
	if dash := strings.index_byte(name_without_extension, '-'); dash >= 0 {
		return name_without_extension[dash + 1:]
	}
	return name_without_extension
}

level_select :: proc(levels: ^[]runtime.Load_Directory_File) -> int {
	dimensions := get_button_dimensions()
	apply_button_text_size(dimensions)
	screen_width := int(rl.GetScreenWidth())
	available_width := max(
		screen_width - dimensions.level_button_margin_x * 2,
		dimensions.level_button_width,
	)
	column_count := max(
		1,
		(available_width + dimensions.level_button_gap_x) /
			(dimensions.level_button_width + dimensions.level_button_gap_x),
	)
	row_width := min(len(levels^), column_count) *
		(dimensions.level_button_width + dimensions.level_button_gap_x) -
		dimensions.level_button_gap_x
	start_x := (screen_width - row_width) / 2

	for level, i in levels^ {
		display_name := pretty_name(level.name)
		name := strings.clone_to_cstring(display_name)
		defer delete(name)
		column := i % column_count
		row := i / column_count
		bounds := rl.Rectangle{
			f32(start_x + column * (dimensions.level_button_width + dimensions.level_button_gap_x)),
			f32(
				dimensions.level_button_start_y +
					row * (dimensions.level_button_height + dimensions.level_button_gap_y),
			),
			f32(dimensions.level_button_width),
			f32(dimensions.level_button_height),
		}
		if rl.GuiButton(bounds, name) {
			return i
		}
	}

	return -1
}
