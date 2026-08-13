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

Rewind_Status :: enum u32 {
	Rewound       = 0,
	History_Empty = 1,
}

JSON_Load_Status :: enum u32 {
	Loaded        = 0,
	Invalid_JSON  = 1,
	Invalid_Level = 2,
}

JSON_Error_Code :: enum u32 {
	Invalid_JSON         = 0,
	Document_Too_Large   = 1,
	Nesting_Too_Deep     = 2,
	Root_Not_Object      = 3,
	Missing_Member       = 4,
	Unknown_Member       = 5,
	Duplicate_Member     = 6,
	Invalid_Member_Type  = 7,
	Integer_Out_Of_Range = 8,
	Invalid_Enum_Value   = 9,
	Invalid_Format       = 10,
	Unsupported_Version  = 11,
	Invalid_Entity_ID    = 12,
}

Validation_Error_Code :: enum u32 {
	Invalid_Dimensions            = 0,
	Invalid_Coordinate_System     = 1,
	Cell_Count_Mismatch           = 2,
	Cell_Out_Of_Bounds            = 3,
	Duplicate_Cell                = 4,
	Invalid_Cell_Height           = 5,
	Invalid_Ramp_Direction        = 6,
	Invalid_Ramp_Endpoints        = 7,
	Fixture_Out_Of_Bounds         = 8,
	Fixture_On_Ramp               = 9,
	Duplicate_Fixture             = 10,
	Invalid_Fixture_Color         = 11,
	Entity_Out_Of_Bounds          = 12,
	Duplicate_Entity_ID           = 13,
	Invalid_Entity_Kind           = 14,
	Entity_Below_Surface          = 15,
	Overlapping_Entities          = 16,
	Player_Not_Top_Of_Stack       = 17,
	Player_Count_Not_One          = 18,
	Invalid_Teleporter_Occupancy  = 19,
	Invalid_Entity_ID             = 20,
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

Validation_Error :: struct {
	code:       Validation_Error_Code,
	coordinate: Coordinate,
	entity_id:  u64,
}

JSON_Error :: struct {
	code:        JSON_Error_Code,
	byte_offset: u32,
	path:        cstring,
	path_length: u32,
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

// State_Result owns every pointer reachable from state through owned_storage.
// Do not copy it while owned; call dispose_state_result exactly once after use.
State_Result :: struct {
	has_state:     u32,
	state:         Snapshot,
	owned_storage: rawptr,
}

// JSON_Load_Result owns every pointer reachable from it through owned_storage.
// Do not copy it while owned; call dispose_json_load_result exactly once after use.
JSON_Load_Result :: struct {
	status:            JSON_Load_Status,
	accepted:          u32,
	json_error:        JSON_Error,
	errors:            ^Validation_Error,
	error_count:       u32,
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

// Rewind_Result owns every pointer reachable from it through owned_storage.
// Do not copy it while owned; call dispose_rewind_result exactly once after use.
Rewind_Result :: struct {
	status:             Rewind_Status,
	accepted:           u32,
	events:             ^Event,
	event_count:        u32,
	has_restored_state: u32,
	restored_state:     Resolved_State,
	has_state:          u32,
	state:              Snapshot,
	has_outcome:        u32,
	outcome:            Outcome,
	owned_storage:      rawptr,
}

// Native 64-bit C ABI layout checks. The C library has matching static assertions.
when size_of(rawptr) == 8 {
	#assert(size_of(Coordinate) == 8)
	#assert(size_of(Coordinate_System) == 16)
	#assert(size_of(Cell) == 20)
	#assert(size_of(Fixture) == 16)
	#assert(size_of(Entity) == 24)
	#assert(size_of(Validation_Error) == 24)
	#assert(size_of(JSON_Error) == 24)
	#assert(size_of(Resolved_State) == 64)
	#assert(size_of(Level) == 56)
	#assert(size_of(Snapshot) == 120)
	#assert(size_of(State_Result) == 136)
	#assert(offset_of(State_Result, state) == 8)
	#assert(offset_of(State_Result, owned_storage) == 128)
	#assert(size_of(JSON_Load_Result) == 336)
	#assert(offset_of(JSON_Load_Result, json_error) == 8)
	#assert(offset_of(JSON_Load_Result, initial_state) == 48)
	#assert(offset_of(JSON_Load_Result, ticks) == 112)
	#assert(offset_of(JSON_Load_Result, final_state) == 128)
	#assert(offset_of(JSON_Load_Result, state) == 200)
	#assert(offset_of(JSON_Load_Result, owned_storage) == 328)
	#assert(size_of(Event) == 80)
	#assert(size_of(Tick) == 88)
	#assert(size_of(Move_Result) == 320)
	#assert(offset_of(Move_Result, events) == 16)
	#assert(offset_of(Move_Result, initial_state) == 32)
	#assert(offset_of(Move_Result, ticks) == 96)
	#assert(offset_of(Move_Result, final_state) == 112)
	#assert(offset_of(Move_Result, state) == 184)
	#assert(offset_of(Move_Result, owned_storage) == 312)
	#assert(size_of(Rewind_Result) == 232)
	#assert(offset_of(Rewind_Result, events) == 8)
	#assert(offset_of(Rewind_Result, restored_state) == 24)
	#assert(offset_of(Rewind_Result, state) == 96)
	#assert(offset_of(Rewind_Result, owned_storage) == 224)
}
