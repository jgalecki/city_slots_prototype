extends GameScreen

class_name CityScreen
var map:DataMap

@export var building_options_screen:BuildingOptionsScreen
@export var slots_screen:SlotsScreen

@export var start_slots_panel:PanelContainer
@export var cash_display:Label
@export var layer_display:Label
@export var days_til_rent_display:Label
@export var rent_needed_display:Label

@export var structures: Array[Structure] = []
# var structuresIndex:int = 2 # Index into structures of the structure being built
var chosen_structure:Structure
var placed_structures: Array[PlacedStructure] = [] # A list of unique buildings placed. Multi-cell buildings are in once.
var grid_structures: = [[[]]]	# A quick way to check if a grid cell has a building on it, or what building it has on it.

var layer:int = 0 # Layer currently viewed
signal layer_changed(new_layer:int)

@export var selector:Node3D # The 'cursor'
@export var selector_container:Node3D # Node that holds a preview of the structure
@export var view_camera:Camera3D # Used for raycasting mouse
@export var gridmap:GridMap

var taxman:Taxman
var in_build_mode:bool

var planes = [] # Used for raycasting mouse

func initialize():
	map = DataMap.new()
	taxman = Taxman.new()
	placed_structures = []
	grid_structures = []
	planes = []
	print("Outside loop: grid_structures has size of " + str(grid_structures.size()))
	for y in range(5):
		planes.append(Plane(Vector3.UP, Vector3(0, y, 0)))
		grid_structures.append([])
		print("y = " + str(y) + ": grid_structures has size of " + str(grid_structures.size()))
		for z in range(4):
			grid_structures[y].append([])
			print("y = " + str(y) + ", z = " + str(z) + ": grid_structures[y] has size of " + str(grid_structures[y].size()))
			for x in range(4):
				grid_structures[y][z].append(structures[0])
				print("y = " + str(y) + ", z = " + str(z) + ", x = " + str(x) + ": grid_structures[y][z] has size of " + str(grid_structures[y][z].size()))
				
	print("Outside loop: grid_structures has size of " + str(grid_structures.size()))
	# print_grid_structures()
	
	# Create new MeshLibrary dynamically, can also be done in the editor
	# See: https://docs.godotengine.org/en/stable/tutorials/3d/using_gridmaps.html
	
	var mesh_library = MeshLibrary.new()
	
	for structure in structures:
		
		var id = mesh_library.get_last_unused_item_id()
		
		mesh_library.create_item(id)
		mesh_library.set_item_mesh(id, get_mesh(structure.model))
		mesh_library.set_item_mesh_transform(id, Transform3D())
		
	gridmap.mesh_library = mesh_library
	
	for i in range(4):
		for j in range(4):
			for k in range(4):
				gridmap.set_cell_item(Vector3i(i, j, k), 0)
			
	
	layer_changed.emit(layer)
	
	selector.visible = false
	start_slots_panel.visible = false
	update_base_ui()	
	
	# good enough for now, random selection later...
	building_options_screen.set_buildings(structures[2], structures[3], structures[4])
	screen_manager.add_screen(building_options_screen)

func controlled_update(delta):
	
	# Controls
	
	action_rotate() # Rotates selection 90 degrees
	# action_structure_toggle() # Toggles between structures
	action_layer_change() # Checks for layer change input
	
#	action_save() # Saving
#	action_load() # Loading
	
	# Map position based on mouse
	
	if selector.visible:
		var world_position = planes[layer].intersects_ray(
			view_camera.project_ray_origin(get_viewport().get_mouse_position()),
			view_camera.project_ray_normal(get_viewport().get_mouse_position()))

		var gridmap_position = Vector3i(round(world_position.x), layer, round(world_position.z))
		var selector_grid_position = Vector3(gridmap_position.x * 1.2, gridmap_position.y * 1.2, gridmap_position.z * 1.2)		# size of cells in Gridmap
		selector.position = lerp(selector.position, selector_grid_position, delta * 40)
		
		action_build(gridmap_position)
		
# Retrieve the mesh from a PackedScene, used for dynamically creating a MeshLibrary

func get_mesh(packed_scene):
	var scene_state:SceneState = packed_scene.get_state()
	for i in range(scene_state.get_node_count()):
		if(scene_state.get_node_type(i) == "MeshInstance3D"):
			for j in scene_state.get_node_property_count(i):
				var prop_name = scene_state.get_node_property_name(i, j)
				if prop_name == "mesh":
					var prop_value = scene_state.get_node_property_value(i, j)
					
					return prop_value.duplicate()

# Build (place) a structure

func action_build(gridmap_position:Vector3i):
	if Input.is_action_just_pressed("build"):
		
		if illegal_build_position(gridmap_position, chosen_structure):
			return
			
		var mesh_lib_index = 0
		for i in range(structures.size()):
			if structures[i].type == chosen_structure.type:
				mesh_lib_index = i
		assert(mesh_lib_index != 0)		
		
		
		var placed_structure = PlacedStructure.new(chosen_structure, get_facing_from_selector(), \
									gridmap_position.x, gridmap_position.y, gridmap_position.z)
		
		placed_structures.append(placed_structure)
		gridmap.set_cell_item(gridmap_position, mesh_lib_index, gridmap.get_orthogonal_index_from_basis(selector.basis))
		
		var cells = placed_structure.get_cells(get_facing_from_selector())	
		for position in cells:
			grid_structures[position.y][position.z][position.x] = chosen_structure
			# If we have a multi-cell structure, remove the current 'empty frame' from gridmap
			if position != gridmap_position:
				print("resetting grid at " + str(position))
				gridmap.set_cell_item(position, -1)
		
		
		update_base_ui()		
		selector.visible = false		
		in_build_mode = false;
		_on_layer_changed(layer)
		start_slots_panel.visible = true
		
		
# Rotates the 'cursor' 90 degrees

func action_rotate():
	if Input.is_action_just_pressed("rotate"):
		selector.rotate_y(deg_to_rad(90))

func action_layer_change():
	if (Input.is_action_just_pressed("layer_up")):
		layer = wrap(layer + 1, 0, 5)
		layer_changed.emit(layer)
	
	if (Input.is_action_just_pressed("layer_down")):
		layer = wrap(layer - 1, 0, 5)
		layer_changed.emit(layer)
		

# Update the structure visual in the 'cursor'

func update_structure(structure:Structure):
	# Clear previous structure preview in selector
	for n in selector_container.get_children():
		selector_container.remove_child(n)
		
	chosen_structure = structure		
		
	print("chosen building type is " + str(structure.type))
	
	# Create new structure preview in selector
	var _model = structure.model.instantiate()
	selector_container.add_child(_model)
	_model.position.y += 0.25
	
func update_base_ui():
	cash_display.text = "$0"# + str(map.cash)
	layer_display.text = str(layer)
	days_til_rent_display.text = str(taxman.days_until_tax(map.day))
	rent_needed_display.text = str(taxman.tax_needed_for_next_rent(map.day))

# Saving/load

#func action_save():
#	if Input.is_action_just_pressed("save"):
#		print("Saving map...")
#
#		for cell in gridmap.get_used_cells():
#
#			var data_structure:DataStructure = DataStructure.new()
#
#			data_structure.position = Vector2i(cell.x, cell.z)
#			data_structure.orientation = gridmap.get_cell_item_orientation(cell)
#			data_structure.structure = gridmap.get_cell_item(cell)
			
#			map.structures.append(data_structure)
#
#		ResourceSaver.save(map, "user://map.res")
	
#func action_load():
#	if Input.is_action_just_pressed("load"):
#		print("Loading map...")
#
#		gridmap.clear()
#
#		map = ResourceLoader.load("user://map.res")
#
#		for cell in map.structures:
#			gridmap.set_cell_item(Vector3i(cell.position.x, 0, cell.position.y), cell.structure, cell.orientation)
#
#		update_base_ui()


func _on_layer_changed(new_layer):
	layer = new_layer
	update_base_ui()
	
	gridmap.clear()		# sets all indices to -1, aka nothing
	
	for struct in placed_structures:
		if struct.pos_y <= layer:
			# TODO: This won't handle multi-y level structures well. Think on.
			var cell = Vector3i(struct.pos_x, struct.pos_y, struct.pos_z)
			gridmap.set_cell_item(cell, struct.mesh_lib_index, struct.get_ortho_basis_from_facing())
	
	# Fill in cube frames on anything build-able at this layer
	for z in range(4):
		for x in range(4):
			var buildable = true
			for y in range(layer + 1):	
				print("y = " + str(y) + ", z = " + str(z) + ", x = " + str(x) + ": grid_structures[y][z][x] type is " + str(grid_structures[y][z][x].type))
				if grid_structures[y][z][x].type == Structure.Type.Empty && in_build_mode:
					var frameIndex = 1
					if y == layer:
						frameIndex = 0
					gridmap.set_cell_item(Vector3i(x, y, z), frameIndex)
					break
					
				
	#for y in range(5):
	#	for z in range(4):
	#		for x in range(4):
	#			var cell = Vector3i(x, y, z)
	###			if y > new_layer:
		#			gridmap.set_cell_item(cell, -1 ) 
		#		elif placed_structures.any(func(structure): structure.get_cells.has)
		#		else:
		#			#TODO: Currently not respecting orientation or multi-celled buildings
		#			gridmap.set_cell_item(cell, grid_structures[y][z][x])
	
#func print_grid_structures():
#	for y in range(4,-1,-1):
#		print ("layer: " + str(y))
#		for z in range(4):
#			print(str(grid_structures[y][z][0]) + " " + str(grid_structures[y][z][1]) + " " + str(grid_structures[y][z][2]) + " " + str(grid_structures[y][z][3]))

func illegal_build_position(position:Vector3i, structure:Structure) -> bool:
	if position.x < 0 || position.x > 3		\
		   || position.z < 0 || position.z > 3:
		#print("Initial tile outside of grid! At " + str(position))
		return true
		
		# print("Attempted block placement at " + str(position))
		
	var facing = get_facing_from_selector()
			
	for dy in range(structure.y_size):
		for dz in range(structure.z_size):
			for dx in range(structure.x_size):
				var faced_dx = 0
				var faced_dz = 0
				if facing == structure.Facing.SW:
					faced_dx = dx
					faced_dz = -1 * dz
				elif facing == structure.Facing.SE:
					faced_dx = -1 * dz
					faced_dz = -1 * dx
				elif facing == structure.Facing.NE:
					faced_dx = -1 * dx
					faced_dz = dz
				else:
					faced_dx = dz
					faced_dz = dx 
				# Assumes structures are not concave - no L tetraminos.
				var new_pos = position + Vector3i(faced_dx, dy, faced_dz)
				if new_pos.x < 0 || new_pos.x > 3 			\
						|| new_pos.z < 0 || new_pos.z > 3 	\
						|| new_pos.y < 0 || new_pos.y > 4:
					return true
				if grid_structures[new_pos.y][new_pos.z][new_pos.x].Type != Structure.Type.Empty:
					# Building already here
					return true
				if new_pos.y > 0 && grid_structures[new_pos.y - 1][new_pos.z][new_pos.x].Type == Structure.Type.Empty:
					# Overhang or unsupported placement
					return true
					
						
	return false;

func get_facing_from_selector() -> Structure.Facing:
	var orthoIndex = gridmap.get_orthogonal_index_from_basis(selector.basis)
	# By experimental testing (and with standard facing), this function returns the following indices:
	# SW: 0 -> SW
	# SE: 16 -> SE
	# NE: 10 -> NE
	# NW: 22 -> NW
	if orthoIndex == 0:
		return Structure.Facing.SW
	if orthoIndex == 16:
		return Structure.Facing.SE
	elif orthoIndex == 10:
		return Structure.Facing.NE
	else: # orthoIndex == 22:
		return Structure.Facing.NW


func _on_building_option_chosen(building):
	selector.visible = true
	in_build_mode = true;
	_on_layer_changed(layer)		# not really changed, but this should turn on the empty frames.
	update_structure(building)


func _on_start_slots_button_pressed():
	var highest_y_layer = 0
	# Slightly inefficient. Whateves.
	for y in range(5):
		for z in range(4):
			for x in range(4):
				if grid_structures[y][z][x].Type != Structure.Type.Empty:
					highest_y_layer = y
					
	
	in_build_mode = false
	layer_changed.emit(highest_y_layer)
	slots_screen.set_up(placed_structures, grid_structures, highest_y_layer)
	screen_manager.add_screen(slots_screen)


func _on_slots_over():
	building_options_screen.set_buildings(structures[2], structures[3], structures[4])
	screen_manager.add_screen(building_options_screen)
