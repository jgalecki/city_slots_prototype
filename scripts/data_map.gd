extends Resource
class_name DataMap

@export var cash:int = 0
@export var day:int = 1
#@export var structures:Array[DataStructure]

# A list of unique buildings placed. Multi-cell buildings are in once.
@export var placed_structures: Array[PlacedStructure] = [] 
# A quick way to check if a grid cell has a building on it, or what building it has on it.
@export var grid_structures: = [[[]]]	

func _init():
	placed_structures = []
	grid_structures = []
	for y in range(5):
		grid_structures.append([])
		for z in range(4):
			grid_structures[y].append([])
			for x in range(4):
				grid_structures[y][z].append(-1)

func has_structure_at(position:Vector3i) -> bool:
	assert(is_in_bounds(position))
	return grid_structures[position.y][position.z][position.x] != -1

func get_structure_at(position:Vector3i) -> PlacedStructure:
	if not has_structure_at(position):
		print("No structure found at " + str(position))
		assert(false)
		
	var  placed_structure_index = grid_structures[position.y][position.z][position.x]
	assert(placed_structure_index >= 0 && placed_structure_index < placed_structures.size())
	
	return placed_structures[placed_structure_index]

func is_in_bounds(position:Vector3i) -> bool:
	return position.x >= 0 && position.x <= 3 		\
			&& position.y >= 0 && position.y <= 4 	\
			&& position.z >= 0 && position.z <= 3

func is_in_bounds_2d(position:Vector2i) -> bool:
	return position.x >= 0 && position.x <= 3 		\
			&& position.y >= 0 && position.y <= 3 
