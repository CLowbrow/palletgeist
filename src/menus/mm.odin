package menus

import rl "vendor:raylib"

Main_Menu_Action :: enum {
	None,
	Play,
	Quit,
	SelectLevel,
}

main_menu :: proc() -> Main_Menu_Action {
	dimensions := get_button_dimensions()
	apply_button_text_size(dimensions)
	x := f32(48)
	width := f32(dimensions.level_button_width)
	height := f32(dimensions.level_button_height)
	stride_y := dimensions.level_button_height + dimensions.level_button_gap_y

	if rl.GuiButton(rl.Rectangle{x, f32(dimensions.level_button_start_y), width, height}, "Play") {
		return .Play
	}
	if rl.GuiButton(
		rl.Rectangle{x, f32(dimensions.level_button_start_y + stride_y), width, height},
		"Select Level",
	) {
		return .SelectLevel
	}
	if rl.GuiButton(
		rl.Rectangle{x, f32(dimensions.level_button_start_y + stride_y * 2), width, height},
		"Quit",
	) {
		return .Quit
	}

	return .None
}
