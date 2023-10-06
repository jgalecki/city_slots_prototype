extends GameScreen

class_name SlotsScreen

@export var layer_info_group:Control
@export var layer_label:Label
@export var cash_label:Label
var cash_amount:int
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

var no_symbols:bool
var only_symbols_phase:bool
var symbol_cashout_phase:bool
var layer:int
signal layer_changed(new_layer:int)

signal slots_over(cash_gained:int)

func initialize():
	layer_info_group.visible = false
	tile_grid = [[grid_0_0, grid_1_0, grid_2_0, grid_3_0],		\
					[grid_0_1, grid_1_1, grid_2_1, grid_3_1],	\
					[grid_0_2, grid_1_2, grid_2_2, grid_3_2],	\
					[grid_0_3, grid_1_3, grid_2_3, grid_3_3]]
	only_symbols_phase = false
	cash_amount = 0
	
	var rolled_symbols = roll_symbols()
	if no_symbols:
		next_phase_button.text = "Next Layer"	
	else:
		next_phase_button.text = "Top Layer"
	
	assert(rolled_symbols.size() == 16)
	symbols_grid = []
	for z in range(4):
		symbols_grid.append([])
		for x in range(4):
			symbols_grid[z].append(rolled_symbols[z * 4 + x])
	
	
	_on_layer_changed(layer)

# Needs to be called before initialize	
func set_up(placed_structures:Array[PlacedStructure], grid_structures, starting_layer:int):
	structures = placed_structures
	structure_grid = grid_structures
	layer = starting_layer


func _on_layer_changed(new_layer):
	layer = new_layer
	layer_label.text = str(layer)
	
	show_layer_in_grid()
	if not only_symbols_phase:
		calculate_layer_effects()	
	
func show_layer_in_grid():
	for z in range(4):
		for x in range(4):
			tile_grid[z][x].visible = true
			tile_grid[z][x].set_symbol(symbols_grid[z][x])
				
			if only_symbols_phase:
				tile_grid[z][x].background_tile_image.visible = false
				tile_grid[z][x].cash_group.visible = false
			else:
				tile_grid[z][x].background_tile_image.visible = true
				tile_grid[z][x].cash_group.visible = true
				# works for no building too.
				tile_grid[z][x].set_background_tile_to_building(structure_grid[layer][z][x].typeFamily)
				# later on, work out things like park doubling house taxes
				tile_grid[z][x].set_cash_label(structure_grid[layer][z][x])
				
	layer_info_group.visible = not only_symbols_phase
	
				
func calculate_layer_effects():
	# pre-income effects (e.g., doubling income, halving income
	for z in range(4):
		for x in range(4):
			if structure_grid[layer][z][x].type == Structure.Types.SmallPark:
				for dz in range(-1, 2, 1):
					for dx in range(-1, 2, 1):
						var cell = Vector2i(x + dx, z + dz)
						if cell.x < 0 || cell.x > 3 || cell.y < 0 || cell.y > 3:
							continue
						print("Checking park at cell " + str(cell))
						if structure_grid[layer][cell.y][cell.x].family == Structure.Families.Residential:
							structure_grid[layer][cell.y][cell.x].temp_income += 1
						
	
	# income effects
	for z in range(4):
		for x in range(4):
			# HIDDEN ASSUMPTION: income producing buildings are only 1x1x1.
			# TO FIX: maybe mark each building in structures as income-generated this turn or not.
			cash_amount += structure_grid[layer][z][x].income
	cash_label.text = str(cash_amount)

	# symbol manipulation
	for z in range(4):
		for x in range(4):
			check_structure_effects(x, z)
	
	# UI updates
	if layer == 0:
		if no_symbols:
			next_phase_button.text = "Next Day"	
		else:
			symbol_cashout_phase = true			
			next_phase_button.text = "CASH OUT"
	
func symbol_cashout():
	assert(layer == 0)
	for z in range(4):
		for x in range(4):
			# TODO: quick anim for destroying each symbol
			cash_amount += symbols_grid[z][x].value
			tile_grid[z][x].background_tile_image.visible = false
			if symbols_grid[z][x].type != Symbol.Types.Empty:
				tile_grid[z][x].symbol_image.visible = false
				tile_grid[z][x].cash_group.visible = true
				tile_grid[z][x].cash_label.text = str(symbols_grid[z][x].value)
				
			
	cash_label.text = str(cash_amount)
	next_phase_button.text = "Next Day"
	
	symbol_cashout_phase = false
	

func _on_next_phase_button_pressed():
	if only_symbols_phase:
		only_symbols_phase = false
		show_layer_in_grid()
		calculate_layer_effects()
	elif layer > 0:
		layer_changed.emit(layer - 1)
	elif symbol_cashout_phase:
		symbol_cashout()
	else:
		exit_screen()
		slots_over.emit(cash_amount)
		
func roll_symbols() -> Array[Symbol]:
	var all_symbols:Array[Symbol] = []
	for placed_structure in structures:
		all_symbols.append_array(placed_structure.structure.symbols)
		
	# If nothing produces Symbols, then there's no point to showing the symbols only layer...
	if all_symbols.size() == 0:
		no_symbols = true
	else:
		only_symbols_phase = true
	if all_symbols.size() > 16:
		all_symbols.shuffle()
		return all_symbols.slice(0, 16)
	else:
		for i in range(all_symbols.size(), 16):
			all_symbols.append(symbols[0])
			
		all_symbols.shuffle()
		return all_symbols
	
func check_structure_effects(x:int, z:int):
	if structure_grid[layer][z][x].type == Structure.Types.Empty:
		return
	if symbols_grid[z][x].type == Symbol.Types.Empty:
		return
	
	# WARNING: currently assumes no symbol-manipulating building actually has income
	match structure_grid[layer][z][x].type:
		Structure.Types.TrainStation:
			if symbols_grid[z][x].family == Symbol.Families.Goods:
				symbols_grid[z][x] = symbols[0]
				tile_grid[z][x].symbol_image.visible = false
				tile_grid[z][x].cash_group.visible = true
				tile_grid[z][x].cash_label.text = "5x"
				cash_amount += 5				
	
