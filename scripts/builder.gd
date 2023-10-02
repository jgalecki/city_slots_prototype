extends Node3D

@export var structures: Array[Structure] = []

var map:DataMap

var structureIndex:int = 0 # Index of structure being built
var layer:int = 0 # Layer currently viewed
var grid_structures = [[[]]]

@export var selector:Node3D # The 'cursor'
@export var selector_container:Node3D # Node that holds a preview of the structure
@export var view_camera:Camera3D # Used for raycasting mouse
@export var gridmap:GridMap
@export var cash_display:Label
@export var layer_display:Label

var planes = [] # Used for raycasting mouse

signal layer_changed(new_layer:int)

func _ready():
	
	map = DataMap.new()
	grid_structures = []
	planes = []
	for y in range(5):
		planes.append(Plane(Vector3.UP, Vector3(0, y, 0)))
		grid_structures.append([])
		for z in range(4):
			grid_structures[y].append([])
			for x in range(4):
				grid_structures[y][z].append(0)
				
	print_grid_structures()
	
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
	
	update_structure()
	update_base_ui()

func _process(delta):
	
	# Controls
	
	action_rotate() # Rotates selection 90 degrees
	action_structure_toggle() # Toggles between structures
	action_layer_change() # Checks for layer change input
	
	action_save() # Saving
	action_load() # Loading
	
	# Map position based on mouse
	
	var world_position = planes[layer].intersects_ray(
		view_camera.project_ray_origin(get_viewport().get_mouse_position()),
		view_camera.project_ray_normal(get_viewport().get_mouse_position()))

	var gridmap_position = Vector3(round(world_position.x), layer, round(world_position.z))
	var selector_grid_position = gridmap_position * 1.2		# size of cells in Gridmap
	selector.position = lerp(selector.position, selector_grid_position, delta * 40)
	
	action_build(gridmap_position)
	action_demolish(gridmap_position)

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

func action_build(gridmap_position):
	if Input.is_action_just_pressed("build"):
		
		if gridmap_position.x < 0 || gridmap_position.x > 3				\
		   || gridmap_position.z < 0 || gridmap_position.z > 3:
			print("failed placement! at " + str(gridmap_position))
			return
		
		print("Placed block at " + str(gridmap_position))
		var previous_tile = gridmap.get_cell_item(gridmap_position)
		gridmap.set_cell_item(gridmap_position, structureIndex, gridmap.get_orthogonal_index_from_basis(selector.basis))
		grid_structures[gridmap_position.y][gridmap_position.z][gridmap_position.x] = structureIndex
		
		if previous_tile != structureIndex:
			map.cash -= structures[structureIndex].price
			update_base_ui()
			
		print_grid_structures()

# Demolish (remove) a structure

func action_demolish(gridmap_position):
	if Input.is_action_just_pressed("demolish"):
		gridmap.set_cell_item(gridmap_position, -1)
		grid_structures[gridmap_position.y][gridmap_position.z][gridmap_position.x]

# Rotates the 'cursor' 90 degrees

func action_rotate():
	if Input.is_action_just_pressed("rotate"):
		selector.rotate_y(deg_to_rad(90))

# Toggle between structures to build

func action_structure_toggle():
	if Input.is_action_just_pressed("structure_next"):
		structureIndex = wrap(structureIndex + 1, 0, structures.size())
	
	if Input.is_action_just_pressed("structure_previous"):
		structureIndex = wrap(structureIndex - 1, 0, structures.size())

	update_structure()

func action_layer_change():
	if (Input.is_action_just_pressed("layer_up")):
		layer = wrap(layer + 1, 0, 5)
		layer_changed.emit(layer)
	
	if (Input.is_action_just_pressed("layer_down")):
		layer = wrap(layer - 1, 0, 5)
		layer_changed.emit(layer)
		

# Update the structure visual in the 'cursor'

func update_structure():
	# Clear previous structure preview in selector
	for n in selector_container.get_children():
		selector_container.remove_child(n)
		
	# Create new structure preview in selector
	var _model = structures[structureIndex].model.instantiate()
	selector_container.add_child(_model)
	_model.position.y += 0.25
	
func update_base_ui():
	cash_display.text = "$" + str(map.cash)
	layer_display.text = str(layer)

# Saving/load

func action_save():
	if Input.is_action_just_pressed("save"):
		print("Saving map...")
		
		for cell in gridmap.get_used_cells():
			
			var data_structure:DataStructure = DataStructure.new()
			
			data_structure.position = Vector2i(cell.x, cell.z)
			data_structure.orientation = gridmap.get_cell_item_orientation(cell)
			data_structure.structure = gridmap.get_cell_item(cell)
			
			map.structures.append(data_structure)
			
		ResourceSaver.save(map, "user://map.res")
	
func action_load():
	if Input.is_action_just_pressed("load"):
		print("Loading map...")
		
		gridmap.clear()
		
		map = ResourceLoader.load("user://map.res")
		
		for cell in map.structures:
			gridmap.set_cell_item(Vector3i(cell.position.x, 0, cell.position.y), cell.structure, cell.orientation)
			
		update_base_ui()


func _on_layer_changed(new_layer):
	update_base_ui()
	
	for y in range(5):
		for z in range(4):
			for x in range(4):
				var cell = Vector3i(x, y, z)
				if y > new_layer:
					gridmap.set_cell_item(cell, -1 ) 
				else:
					gridmap.set_cell_item(cell, grid_structures[y][z][x])
	
func print_grid_structures():
	for y in range(4,-1,-1):
		print ("layer: " + str(y))
		for z in range(4):
			print(str(grid_structures[y][z][0]) + " " + str(grid_structures[y][z][1]) + " " + str(grid_structures[y][z][2]) + " " + str(grid_structures[y][z][3]))
