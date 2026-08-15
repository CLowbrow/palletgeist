package game_state

import rules "../game_rules"

// World_State owns one immutable snapshot allocation supplied by the C rules
// library. Views into owned.state remain valid until refresh or unload.
World_State :: struct {
	owned: rules.State_Result,
}

unload :: proc(state: ^World_State) {
	if state == nil {
		return
	}

	rules.dispose_state_result(&state.owned)
}

// refresh prepares the next owner before disposing the current one, leaving
// the existing world intact if the C call fails or has no state.
refresh :: proc(state: ^World_State, engine: ^rules.Engine) -> bool {
	if state == nil || engine == nil {
		return false
	}

	next: rules.State_Result
	if rules.get_state(engine, &next) != .Ok || next.has_state == 0 {
		rules.dispose_state_result(&next)
		return false
	}

	rules.dispose_state_result(&state.owned)
	state.owned = next
	next = {}
	return true
}

snapshot :: proc(state: ^World_State) -> (snapshot: ^rules.Snapshot, ok: bool) {
	if state == nil || state.owned.has_state == 0 || state.owned.owned_storage == nil {
		return
	}

	snapshot = &state.owned.state
	ok = true
	return
}

player :: proc(state: ^World_State) -> (entity: rules.Entity, ok: bool) {
	current, loaded := snapshot(state)
	if !loaded {
		return
	}

	return player_from_resolved(&current.resolved)
}

player_from_resolved :: proc(resolved: ^rules.Resolved_State) -> (entity: rules.Entity, ok: bool) {
	if resolved == nil {
		return
	}

	for candidate in rules.entities_view(resolved) {
		if candidate.kind == .Player {
			return candidate, true
		}
	}

	return
}
