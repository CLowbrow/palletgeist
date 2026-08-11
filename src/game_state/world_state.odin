// Don't retain c pointers in here
package game_state

import rules "../game_rules"
import "core:mem"

World_State :: struct {
	entities: []rules.Entity,
	outcome:  rules.Outcome,
	loaded:   bool,
}

unload :: proc(state: ^World_State) {
	if state == nil {
		return
	}

	delete(state.entities)
	state.entities = nil
	state.outcome = .Ongoing
	state.loaded = false
}

// Add the static level collections here when they move out of their renderers.
replace_from_snapshot :: proc(state: ^World_State, snapshot: ^rules.Snapshot) -> bool {
	if snapshot == nil {
		return false
	}

	return replace_from_resolved(state, &snapshot.resolved)
}

// replace_from_resolved deep-copies pointer-backed C data before its owning result is disposed.
// The replacement is prepared first so state is not partially updated.
replace_from_resolved :: proc(state: ^World_State, resolved: ^rules.Resolved_State) -> bool {
	if state == nil || resolved == nil {
		return false
	}

	entity_count := int(resolved.entity_count)
	if entity_count > 0 && resolved.entities == nil {
		return false
	}

	next_entities := make([]rules.Entity, entity_count)
	if entity_count > 0 {
		incoming := mem.slice_ptr(resolved.entities, entity_count)
		copy(next_entities, incoming)
	}

	delete(state.entities)
	state.entities = next_entities
	state.outcome = resolved.outcome
	state.loaded = true
	return true
}

player :: proc(state: ^World_State) -> (entity: rules.Entity, ok: bool) {
	if state == nil || !state.loaded {
		return
	}

	for candidate in state.entities {
		if candidate.kind == .Player {
			return candidate, true
		}
	}

	return
}
