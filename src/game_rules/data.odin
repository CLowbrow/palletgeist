// Typed data ABI shared with bomb-box-rules-c/include/game_rules/c_api.h.
// Keep these structs in C field order and do not pack them.
package game_rules

Call_Status :: enum u32 {
	Ok                = 0,
	Invalid_Engine    = 1,
	Invalid_Argument  = 2,
	Allocation_Failed = 3,
}

Horizontal_Direction :: enum u32 {
	East = 0,
	West = 1,
}

Vertical_Direction :: enum u32 {
	North = 0,
	South = 1,
}

Cell_Kind :: enum u32 {
	Flat = 0,
	Ramp = 1,
}

Fixture_Kind :: enum u32 {
	Switch = 0,
	Door   = 1,
	Exit   = 2,
}

Entity_Kind :: enum u32 {
	Player = 0,
	Box    = 1,
	Barrel = 2,
}

Color :: enum u32 {
	Red    = 0,
	Green  = 1,
	Blue   = 2,
	Yellow = 3,
}

Outcome :: enum u32 {
	Ongoing = 0,
	Won     = 1,
	Lost    = 2,
}

Move_Status :: enum u32 {
	Moved                  = 0,
	No_Level               = 1,
	Invalid_Direction      = 2,
	World_Boundary         = 3,
	Ledge                   = 4,
	Occupied                = 5,
	Stacked_Push_Target     = 6,
	Closed_Door             = 7,
	Teleporter_Restriction = 8,
	Unsupported_Geometry   = 9,
	Level_Terminal          = 10,
}

Event_Kind :: enum u32 {
	Move_Blocked    = 0,
	State_Rewound   = 1,
	Entity_Moved    = 2,
	Barrel_Armed    = 3,
	Barrel_Exploded = 4,
	Player_Crushed  = 5,
	Switch_Changed  = 6,
	Door_Opened     = 7,
	Door_Closed     = 8,
	Level_Won       = 9,
	Level_Lost      = 10,
}

Movement_Cause :: enum u32 {
	Player = 0,
	Blast  = 1,
	Fall   = 2,
	Slide  = 3,
}

Coordinate :: struct {
	x: i32,
	y: i32,
}

Coordinate_System :: struct {
	origin:     Coordinate,
	positive_x: Horizontal_Direction,
	positive_y: Vertical_Direction,
}

Cell :: struct {
	coordinate:    Coordinate,
	kind:          Cell_Kind,
	elevation:     i32,
	low_direction: Direction,
}

Fixture :: struct {
	coordinate: Coordinate,
	kind:       Fixture_Kind,
	color:      Color,
}

Entity :: struct {
	id:                u64,
	kind:              Entity_Kind,
	coordinate:        Coordinate,
	bottom_half_steps: i32,
}

Resolved_State :: struct {
	entities:                  ^Entity,
	entity_count:              u32,
	armed_barrel_ids:          ^u64,
	armed_barrel_count:        u32,
	active_switch_colors:      ^Color,
	active_switch_color_count: u32,
	open_doors:                ^Coordinate,
	open_door_count:           u32,
	outcome:                   Outcome,
}

Level :: struct {
	coordinates:   Coordinate_System,
	width:         u32,
	height:        u32,
	cells:         ^Cell,
	cell_count:    u32,
	fixtures:      ^Fixture,
	fixture_count: u32,
}

Snapshot :: struct {
	level:    Level,
	resolved: Resolved_State,
}

Event :: struct {
	kind:                  Event_Kind,
	direction:             Direction,
	move_status:           Move_Status,
	entity_id:             u64,
	other_entity_id:       u64,
	from:                  Coordinate,
	to:                    Coordinate,
	coordinate:            Coordinate,
	old_bottom_half_steps: i32,
	new_bottom_half_steps: i32,
	bottom_half_steps:     i32,
	movement_cause:        Movement_Cause,
	color:                 Color,
	active:                u32,
}

Tick :: struct {
	index:       u32,
	events:      ^Event,
	event_count: u32,
	state_after: Resolved_State,
}

// Move_Result owns every pointer reachable from it through owned_storage.
// Do not copy it while owned; call dispose_move_result exactly once after use.
Move_Result :: struct {
	status:            Move_Status,
	accepted:          u32,
	has_direction:     u32,
	direction:         Direction,
	events:            ^Event,
	event_count:       u32,
	has_initial_state: u32,
	initial_state:     Resolved_State,
	ticks:             ^Tick,
	tick_count:        u32,
	has_final_state:   u32,
	final_state:       Resolved_State,
	has_state:         u32,
	state:             Snapshot,
	has_outcome:       u32,
	outcome:           Outcome,
	owned_storage:     rawptr,
}

// Native 64-bit C ABI layout checks. The C library has matching static assertions.
when size_of(rawptr) == 8 {
	#assert(size_of(Coordinate) == 8)
	#assert(size_of(Coordinate_System) == 16)
	#assert(size_of(Cell) == 20)
	#assert(size_of(Fixture) == 16)
	#assert(size_of(Entity) == 24)
	#assert(size_of(Resolved_State) == 64)
	#assert(size_of(Level) == 56)
	#assert(size_of(Snapshot) == 120)
	#assert(size_of(Event) == 80)
	#assert(size_of(Tick) == 88)
	#assert(size_of(Move_Result) == 320)
	#assert(offset_of(Move_Result, events) == 16)
	#assert(offset_of(Move_Result, initial_state) == 32)
	#assert(offset_of(Move_Result, ticks) == 96)
	#assert(offset_of(Move_Result, final_state) == 112)
	#assert(offset_of(Move_Result, state) == 184)
	#assert(offset_of(Move_Result, owned_storage) == 312)
}
