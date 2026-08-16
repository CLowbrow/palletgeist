// Junk Drawer
package project_helpers

import rules "../game_rules"
import "core:mem"

TICK_TIME_BUDGET :: f32(0.2) // seconds

UI_Mode :: enum {
	MainMenu,
	PauseMenu,
	LevelWon,
	LevelLost,
	Playing,
	LevelSelect,
	Animating,
}

Turn_Animation_Queue :: struct {
	initial_state: ^rules.Resolved_State,
	ticks:         []rules.Tick,
	tick_index:    int,
	tick_elapsed:  f32,
	animating:     bool,
}

ticks_view :: proc(result: ^rules.Move_Result) -> []rules.Tick {
	if result == nil || result.tick_count == 0 || result.ticks == nil {
		return nil
	}

	return mem.slice_ptr(result.ticks, int(result.tick_count))
}

events_view :: proc(tick: ^rules.Tick) -> []rules.Event {
	if tick == nil || tick.event_count == 0 || tick.events == nil {
		return nil
	}

	return mem.slice_ptr(tick.events, int(tick.event_count))
}
