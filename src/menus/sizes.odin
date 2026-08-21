package menus

import rl "vendor:raylib"

REFERENCE_SCREEN_WIDTH :: 1280
BASE_LEVEL_BUTTON_WIDTH :: 180
BASE_LEVEL_BUTTON_HEIGHT :: 44
BASE_LEVEL_BUTTON_GAP_X :: 10
BASE_LEVEL_BUTTON_GAP_Y :: 10
BASE_LEVEL_BUTTON_MARGIN_X :: 32
BASE_LEVEL_BUTTON_START_Y :: 110
BASE_BUTTON_TEXT_SIZE :: 20

Button_Dimensions :: struct {
	level_button_width:    int,
	level_button_height:   int,
	level_button_gap_x:    int,
	level_button_gap_y:    int,
	level_button_margin_x: int,
	level_button_start_y:  int,
	button_text_size:      int,
}

scale_button_dimension :: proc(value, screen_width: int) -> int {
	return max(1, value * screen_width / REFERENCE_SCREEN_WIDTH)
}

get_button_dimensions :: proc() -> Button_Dimensions {
	screen_width := int(rl.GetScreenWidth())

	return Button_Dimensions {
		level_button_width    = scale_button_dimension(BASE_LEVEL_BUTTON_WIDTH, screen_width),
		level_button_height   = scale_button_dimension(BASE_LEVEL_BUTTON_HEIGHT, screen_width),
		level_button_gap_x    = scale_button_dimension(BASE_LEVEL_BUTTON_GAP_X, screen_width),
		level_button_gap_y    = scale_button_dimension(BASE_LEVEL_BUTTON_GAP_Y, screen_width),
		level_button_margin_x = scale_button_dimension(BASE_LEVEL_BUTTON_MARGIN_X, screen_width),
		button_text_size      = scale_button_dimension(BASE_BUTTON_TEXT_SIZE, screen_width),
		// The title is currently fixed-size, so do not let buttons overlap it
		// when the window is narrower than the reference layout.
		level_button_start_y = max(
			BASE_LEVEL_BUTTON_START_Y,
			scale_button_dimension(BASE_LEVEL_BUTTON_START_Y, screen_width),
		),
	}
}

apply_button_text_size :: proc(dimensions: Button_Dimensions) {
	rl.GuiSetStyle(
		.DEFAULT,
		i32(rl.GuiDefaultProperty.TEXT_SIZE),
		i32(dimensions.button_text_size),
	)
}
