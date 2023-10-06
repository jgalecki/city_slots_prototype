extends Node

# Stack-based screen management loosely inspired by XNA / Monogame.
# Screens are added in a stack - the last one added has first dibs on the following:
#   Input - a screen can claim input, or (for passthrough popups) let lower screens grab it.
#   Pause - a screen can prevent all screens below it from updating.
#   Display - a screen can prevent all screens below it from drawing.
class_name GameScreen

# NB: Not set until the screen manager calls add_screen with this screen.
var screen_manager:ScreenManager

enum ScreenState {
	Active,		# Updates, takes input, displays
	Covered,	# Updates, does not take input, displays. Under a popup.
	Paused,		# No updates, no input, displays. Under a pausing screen.
	Hidden		# No updates, no input, no display Under a base screen.
}

# Set these in the Node Inspecter. Controls how the screen is handled.
# These are kinda a hierarchy, except that I've found it useful to sometimes have popup
#   screens that don't claim input. Thus, passthrough_popup
@export var is_passthrough_popup:bool	# Does not pause screen below. Doesn't claim input. (Allows input to 'pass through')
@export var is_popup:bool				# Does not pause screen below. Claims input
@export var is_pause_screen:bool		# Pauses screen below. Claims input.
@export var is_base_screen:bool			# Pauses and hides the screen below. Claims input.

var _higher_screen_taking_input:bool
var _higher_screen_previously_taking_input:bool
func is_handling_input() -> bool:
	return not _higher_screen_taking_input

var _higher_screen_is_pause_screen:bool
var _higher_screen_previously_was_pause_screen:bool
func is_updating() -> bool:
	return not _higher_screen_is_pause_screen
	
var _higher_screen_is_base_screen:bool
var _higher_screen_previously_was_base_screen:bool
func is_displayed() -> bool:
	return not _higher_screen_is_base_screen

func update_screen_state(beneath_input_claiming_screen:bool, beneath_pause_screen:bool, beneath_base_screen:bool):
	_higher_screen_previously_taking_input = _higher_screen_taking_input
	_higher_screen_previously_was_pause_screen = _higher_screen_is_pause_screen
	_higher_screen_previously_was_base_screen = _higher_screen_is_base_screen
	
	_higher_screen_taking_input = beneath_input_claiming_screen
	_higher_screen_is_pause_screen = beneath_pause_screen
	_higher_screen_is_base_screen = beneath_base_screen
	
	# if _higher_screen_is_base_screen && not _higher_screen_previously_was_base_screen:
	#	# set to inactive? Can we do that from the editor?
	#	return
	# elif not _higher_screen_is_base_screen && _higher_screen_previously_was_base_screen:
	#	# set to active
	#	return
	
# Later on, could add screen transition stuff	
func exit_screen():
	screen_manager.remove_screen(self)

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass 

# Old school XNA / monogame stack-based screen management. Replace _ready() and _process() for greater control
func initialize():
	pass
	
func controlled_update(delta):
	pass
	
func constant_update(delta):
	pass
	
func handle_input():
	pass

# initialize() is the equivalent 'on_add()'
func on_removal():
	pass
