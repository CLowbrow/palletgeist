package menus

import rl "vendor:raylib"

Main_Menu_Action :: enum {
	None,
	Play,
	Quit,
	SelectLevel,
}

main_menu :: proc() -> Main_Menu_Action {

	if rl.GuiButton(rl.Rectangle{48, 110, 180, 44}, "Play") {
		return .Play
	}
	if rl.GuiButton(rl.Rectangle{48, 164, 180, 44}, "Select Level") {
		return .SelectLevel
	}
	if rl.GuiButton(rl.Rectangle{48, 218, 180, 44}, "Quit") {
		return .Quit
	}

	return .None
}
