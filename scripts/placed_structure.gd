extends Resource
# Consider this an 'instantiation' of the Structure resource object.
class_name PlacedStructure

enum Facings { SW, SE, NE, NW }

@export var position:Vector3i
@export var facing:Facings		# cardinal orientation of the structure
@export var mesh_lib_index:int 	# index into our mesh library of this struture
@export var structure:Structure # reference to the structure in question

@export var temp_income:int # Tracks temporary (day-long) increases to income.

func income() -> int:
	return structure.base_income + temp_income

func _init(struct:Structure, face:Facings, mlib_index:int, pos:Vector3i):
	position = pos
	facing = face
	mesh_lib_index = mlib_index
	structure = struct

# Function to get every tile covered by a placed structure.
# # TODO: Might be able to work this in with builder::illegal_build_position by passing in a structure
# #   		and a position. Que sera sera
func get_cells(facing:Facings) -> Array[Vector3i]:
	var cells:Array[Vector3i] = []
	for dy in range(structure.y_size):
		for dz in range(structure.z_size):
			for dx in range(structure.x_size):
				var faced_dx = 0
				var faced_dz = 0
				if facing == Facings.SW:
					faced_dx = dx
					faced_dz = -1 * dz
				elif facing == Facings.SE:
					faced_dx = -1 * dz
					faced_dz = -1 * dx
				elif facing == Facings.NE:
					faced_dx = -1 * dx
					faced_dz = dz
				else:
					faced_dx = dz
					faced_dz = dx 
				# Assumes structures are not concave - no L tetraminos.
				cells.append(position + Vector3i(faced_dx, dy, faced_dz))
	return cells

# Gets the 'ortho basis' of the selector when this building was placed.
# Needed to replace buildings in gridmap when layers change
func get_ortho_basis_from_facing() -> int:
	# SW: 0 -> SW
	# SE: 16 -> SE
	# NE: 10 -> NE
	# NW: 22 -> NW
	if facing == Facings.SW:
		return 0
	elif facing == Facings.SE:
		return 16
	elif facing == Facings.NE:
		return 10
	else:
		return 22
