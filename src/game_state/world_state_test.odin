#+build !js

package game_state

import rules "../game_rules"
import "core:testing"

TEST_LEVEL_JSON :: #load("../../levels/01-welcome.json")

load_and_refresh :: proc(engine: ^rules.Engine, state: ^World_State) -> bool {
	result: rules.JSON_Load_Result
	defer rules.dispose_json_load_result(&result)

	if rules.load_level_json_data(engine, transmute([]u8)TEST_LEVEL_JSON, &result) != .Ok {
		return false
	}
	if result.status != .Loaded || result.accepted == 0 || result.has_state == 0 {
		return false
	}
	return refresh(state, engine)
}

@(test)
world_state_retains_c_snapshot_owner :: proc(t: ^testing.T) {
	engine, engine_created := rules.create_engine()
	testing.expect(t, engine_created)
	if !engine_created {
		return
	}
	defer rules.destroy_engine(&engine)

	state: World_State
	defer unload(&state)
	testing.expect(t, load_and_refresh(&engine, &state))

	first_owner := state.owned.owned_storage
	move_result: rules.Move_Result
	call := rules.move(&engine, .East, &move_result)
	if call == .Ok && move_result.has_state != 0 {
		testing.expect(t, refresh(&state, &engine))
	}
	rules.dispose_move_result(&move_result)
	testing.expect(t, state.owned.owned_storage != first_owner)

	rewind_result: rules.Rewind_Result
	rewind_call := rules.rewind(&engine, &rewind_result)
	testing.expect_value(t, rewind_call, rules.Call_Status.Ok)
	testing.expect_value(t, rewind_result.status, rules.Rewind_Status.Rewound)
	testing.expect(t, rewind_result.accepted != 0)
	if rewind_call == .Ok && rewind_result.has_state != 0 {
		testing.expect(t, refresh(&state, &engine))
	}
	rules.dispose_rewind_result(&rewind_result)

	// Result owners are independent of both operation results and the engine.
	rules.destroy_engine(&engine)
	current, loaded := snapshot(&state)
	testing.expect(t, loaded)
	if !loaded {
		return
	}

	testing.expect(t, state.owned.owned_storage != nil)
	testing.expect_value(t, current.level.width, u32(5))
	testing.expect_value(t, len(rules.cells_view(&current.level)), 45)
	_, player_loaded := player(&state)
	testing.expect(t, player_loaded)
}
