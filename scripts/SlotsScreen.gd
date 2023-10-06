extends GameScreen

class_name SlotsScreen

@export var layer_info_group:Control
@export var next_phase_button:Button	# Unsure if needed...

var tile_grid = [[]]
@export var grid_0_0:SlotsTile
@export var grid_0_1:SlotsTile
@export var grid_0_2:SlotsTile
@export var grid_0_3:SlotsTile
@export var grid_1_0:SlotsTile
@export var grid_1_1:SlotsTile
@export var grid_1_2:SlotsTile
@export var grid_1_3:SlotsTile
@export var grid_2_0:SlotsTile
@export var grid_2_1:SlotsTile
@export var grid_2_2:SlotsTile
@export var grid_2_3:SlotsTile
@export var grid_3_0:SlotsTile
@export var grid_3_1:SlotsTile
@export var grid_3_2:SlotsTile
@export var grid_3_3:SlotsTile

var structures:Array[PlacedStructure]
var structure_grid = [[[]]]

@export var symbols: Array[Symbol] = []
var symbols_grid = [[]]

var only_symbols_layer:bool
var layer:int
signal layer_changed(new_layer:int)

signal slots_over()

func initialize():
	layer_info_group.visible = false
	tile_grid = [[grid_0_0, grid_1_0, grid_2_0, grid_3_0],		\
					[grid_0_1, grid_1_1, grid_2_1, grid_3_1],	\
					[grid_0_2, grid_1_2, grid_2_2, grid_3_2],	\
					[grid_0_3, grid_1_3, grid_2_3, grid_3_3]]
	only_symbols_layer = true
	_on_layer_changed(layer)

# Needs to be called before initialize	
func set_up(placed_structures:Array[PlacedStructure], grid_structures, starting_layer:int):
	structures = placed_structures
	structure_grid = grid_structures
	layer = starting_layer


func _on_layer_changed(new_layer):
	layer = new_layer
	show_layer_in_grid()
	
func show_layer_in_grid():
	for z in range(4):
		for x in range(4):
			if only_symbols_layer:
				tile_grid[z][x].visible = false
			else:
				tile_grid[z][x].visible = true
				if symbols_grid[z][x] == 0:
					tile_grid[z][x].set_no_symbol()
				else:
					tile_grid[z][x].set_symbol(symbols_grid[z][x])
				
				# works for no building too.
				tile_grid[z][x].set_background_tile_to_building(structure_grid[layer][z][x].TypeFamily)
				# later on, work out things like park doubling house taxes
				tile_grid[z][x].set_cash_label(structure_grid[layer][z][x])
				


func _on_next_phase_button_pressed():
	if only_symbols_layer:
		only_symbols_layer = false
		show_layer_in_grid()
	elif layer > 0:
		layer_changed.emit(layer - 1)
	else:
		exit_screen()
		slots_over.emit()
	
