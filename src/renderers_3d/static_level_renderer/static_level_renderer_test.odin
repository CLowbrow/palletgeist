package static_level_renderer

import "core:testing"

@(test)
masked_floor_draw_resets_to_default_texture :: proc(t: ^testing.T) {
	mask_texture_id := u32(27)
	default_texture_id := u32(1)

	testing.expect_value(
		t,
		floor_texture_reset_id(mask_texture_id, default_texture_id),
		default_texture_id,
	)
}
