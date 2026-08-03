package menus

import "base:runtime"
import "core:strings"
import rl "vendor:raylib"

pretty_name :: proc(name: string) -> string {
	if dash := strings.index_byte(name, '-'); dash >= 0 {
		return name[dash + 1:]
	}
	return name
}

level_select :: proc(levels: ^[]runtime.Load_Directory_File) -> int {
	for level, i in levels^ {
		display_name := pretty_name(level.name)
		name := strings.clone_to_cstring(display_name)
		defer delete(name)
		if rl.GuiButton(rl.Rectangle{48, 110 + f32(i * 54), 180, 44}, name) {
			return i
		}
	}

	return -1
}
