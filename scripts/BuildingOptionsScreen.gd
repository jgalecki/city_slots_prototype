extends GameScreen

class_name BuildingOptionsScreen

@export var options_panel_a:BuildingOptionsPanel
@export var options_panel_b:BuildingOptionsPanel
@export var options_panel_c:BuildingOptionsPanel

var types_set:bool = false

func set_buildings(building_a:Structure, building_b:Structure, building_c:Structure):
	options_panel_a.set_option(building_a)
	options_panel_b.set_option(building_b)
	options_panel_c.set_option(building_c)
	
	types_set = true

func initialize():
	assert(types_set)
	types_set = false
	
func _on_building_option_chosen(building):
	super.exit_screen()
