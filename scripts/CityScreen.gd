extends GameScreen

class_name CityScreen
var map:DataMap

@export var building_options_screen:BuildingOptionsScreen
@export var slots_screen:SlotsScreen
@export var game_over_screen:GameOverScreen

@export var start_slots_panel:PanelContainer
@export var cash_display:Label
@export var layer_display:Label
@export var days_til_rent_display:Label
@export var rent_needed_display:Label

@export var structures: Array[Structure] = []
# var structuresIndex:int = 2 # Index into structures of the structure being built
var chosen_structure:Structure

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
	planes = []
	for y in range(5):
		planes.append(Plane(Vector3.UP, Vector3(0, y, 0)))
	
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
		for j in range(5):
			for k in range(4):
				gridmap.set_cell_item(Vector3i(i, j, k), 0)
			
	
	layer_changed.emit(layer)
	
	selector.visible = false
	start_slots_panel.visible = false
	update_base_ui()	
	
	# good enough for now, random selection later...
	building_options_screen.set_buildings(structures[2], structures[5], structures[4])
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
									mesh_lib_index, gridmap_position)
									
		map.placed_structures.append(placed_structure)
		var placed_structure_index = map.placed_structures.size() - 1
		gridmap.set_cell_item(gridmap_position, mesh_lib_index, gridmap.get_orthogonal_index_from_basis(selector.basis))
		
		var cells = placed_structure.get_cells(get_facing_from_selector())	
		for position in cells:
			map.grid_structures[position.y][position.z][position.x] = placed_structure_index
			# If we have a multi-cell structure, remove the current 'empty frame' from gridmap
			if position != gridmap_position:
				print("Removing connected empty grid space at " + str(position))
				gridmap.set_cell_item(position, -1)
		
		print("Player placed " + str(chosen_structure.type) + " at position " + str(gridmap_position))
		
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
	cash_display.text = "$" + str(map.cash)
	layer_display.text = str(layer)
	days_til_rent_display.text = str(taxman.days_until_rent(map))
	rent_needed_display.text = str(taxman.money_needed_for_next_rent(map))

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
	
	for struct in map.placed_structures:
		if struct.position.y <= layer:
			# TODO: This won't handle multi-y level structures well. Think on.
			gridmap.set_cell_item(struct.position, struct.mesh_lib_index, struct.get_ortho_basis_from_facing())
	
	# Fill in cube frames on anything build-able at this layer
	for z in range(4):
		for x in range(4):
			var buildable = true
			for y in range(layer + 1):	
				var pos = Vector3i(x, y, z)
				if in_build_mode && not map.has_structure_at(pos):
					var frameIndex = 1
					if y == layer:
						frameIndex = 0
					gridmap.set_cell_item(pos, frameIndex)
					break
					
func illegal_build_position(position:Vector3i, structure:Structure) -> bool:
	if not map.is_in_bounds(position):
		return true
		
	
	# Duplicates code in PlacedStructure, could figure out a way to merge if time
	var facing = get_facing_from_selector()
	
	# Loop assumes buildings are concave, not convex, and checks a bounding box.		
	for dy in range(structure.y_size):
		for dz in range(structure.z_size):
			for dx in range(structure.x_size):
				var faced_dx = 0
				var faced_dz = 0
				if facing == PlacedStructure.Facings.SW:
					faced_dx = dx
					faced_dz = -1 * dz
				elif facing == PlacedStructure.Facings.SE:
					faced_dx = -1 * dz
					faced_dz = -1 * dx
				elif facing == PlacedStructure.Facings.NE:
					faced_dx = -1 * dx
					faced_dz = dz
				else:
					faced_dx = dz
					faced_dz = dx 
				# Assumes structures are not concave - no L tetraminos.
				var new_pos = position + Vector3i(faced_dx, dy, faced_dz)
				if not map.is_in_bounds(new_pos):
					return true
				if map.has_structure_at(new_pos):
					# Building already here
					return true
				var beneath_new_pos = new_pos + Vector3i(0, -1, 0)
				if new_pos.y > 0 && not map.has_structure_at(beneath_new_pos):
					# Overhang or unsupported placement
					return true
					
						
	return false;

func get_facing_from_selector() -> PlacedStructure.Facings:
	var orthoIndex = gridmap.get_orthogonal_index_from_basis(selector.basis)
	# By experimental testing (and with standard facing), this function returns the following indices:
	# SW: 0 -> SW
	# SE: 16 -> SE
	# NE: 10 -> NE
	# NW: 22 -> NW
	if orthoIndex == 0:
		return PlacedStructure.Facings.SW
	if orthoIndex == 16:
		return PlacedStructure.Facings.SE
	elif orthoIndex == 10:
		return PlacedStructure.Facings.NE
	else: # orthoIndex == 22:
		return PlacedStructure.Facings.NW


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
				if map.has_structure_at(Vector3i(x, y, z)):
					highest_y_layer = y
					
	
	print("on Start Slots press, cash is " + str(map.cash))
	in_build_mode = false
	layer_changed.emit(highest_y_layer)
	slots_screen.set_up(map, highest_y_layer)
	screen_manager.add_screen(slots_screen)
	start_slots_panel.visible = false


func _on_slots_over(cash_gained:int):
	print("On day " + str(map.day) + ", player gained " + str(cash_gained))
	print("on Next Day press, cash is " + str(map.cash))
	map.cash += cash_gained
	print("after cahs inc, cash is " + str(map.cash))
	map.day += 1
	update_base_ui()
	
	if taxman.game_over(map):
		screen_manager.add_screen(game_over_screen)
		return
	
	if taxman.days_until_rent(map) == 0:
		map.cash -= taxman.money_needed_for_next_rent(map)
		update_base_ui()
		
		# relic screen or something?	

	building_options_screen.set_buildings(structures[2], structures[5], structures[4])
	screen_manager.add_screen(building_options_screen)	


func _on_restart_button_pressed():
	map = DataMap.new()
	taxman = Taxman.new()
	
	for i in range(4):
		for j in range(5):
			for k in range(4):
				gridmap.set_cell_item(Vector3i(i, j, k), 0)
			
	layer = 0
	layer_changed.emit(layer)
	
	selector.visible = false
	start_slots_panel.visible = false
	update_base_ui()	
	
	# good enough for now, random selection later...
	building_options_screen.set_buildings(structures[2], structures[5], structures[4])
	screen_manager.add_screen(building_options_screen)
