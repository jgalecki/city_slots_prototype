extends Node3D

class_name ScreenManager

@export var initial_screen:GameScreen

var _screens:Array[GameScreen] = []

# Honestly, I don't remember a specific reason why this exists. 
# I just know it was useful to me at some point in the last decade.
var _delayed_update_screen_states:bool

# Called when the node enters the scene tree for the first time.
func _ready():
	_delayed_update_screen_states = false
	add_screen(initial_screen)
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var screens_to_update:Array[GameScreen] = []
	for screen in _screens:
		screens_to_update.append(screen)
		
	screens_to_update.reverse()
	
	for screen in screens_to_update:
		screen.constant_update(delta)
		if screen.is_handling_input():
			screen.handle_input()
		if screen.is_updating():
			screen.controlled_update(delta)
	
	if _delayed_update_screen_states:
		_delayed_update_screen_states = false
		update_screen_states()
		
func update_screen_states():
	# work off of a copy of screens in case one screen adds or removes another
	var screens_copy:Array[GameScreen] = []
	for screen in _screens:
		screens_copy.append(screen)
		
	var input_claimed = false
	var screen_is_pausing = false
	var screen_is_base_screen = false
	
	while screens_copy.size() > 0:
		var screen = screens_copy[-1]
		screens_copy.remove_at(screens_copy.size() - 1)
		screen.update_screen_state(input_claimed, screen_is_pausing, screen_is_base_screen)
		
		# Screens, except for passthrough popups, claim user input.
		if not input_claimed && not screen.is_passthrough_popup:
			input_claimed = true
		if not screen_is_pausing && screen.is_pause_screen:
			screen_is_pausing = true
		if screen.is_base_screen:
			input_claimed = true
			screen_is_pausing = true
			screen_is_base_screen = true
		
func add_screen(screen:GameScreen, shift_states_immediately:bool = false):
	_screens.append(screen)
	
	screen.screen_manager = self
	# set active, if need be
	
	screen.visible = true
	screen.initialize()
	
	if shift_states_immediately:
		update_screen_states()
	else:
		_delayed_update_screen_states = true;
		
func remove_screen(screen:GameScreen, shift_states_immediately:bool = false):
	screen.on_removal()
	
	for i in range(_screens.size()):
		if _screens[i] == screen:
			_screens.remove_at(i)
			break
	
	screen.visible = false		
	
	if shift_states_immediately:
		update_screen_states()
	else:
		_delayed_update_screen_states = true;
	
	if shift_states_immediately:
		update_screen_states()
	else:
		_delayed_update_screen_states = true;
