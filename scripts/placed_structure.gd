extends Object
class_name PlacedStructure

@export var pos_x:int # x coord of the initial building tile
@export var pos_z:int # z coord of the initial building tile
@export var pos_y:int # y coord of the initial building tile
@export var facing:Structure.Facings	# cardinal orientation of the structure
@export var mesh_lib_index:int # index into our mesh library of this struture
@export var structure:Structure # reference to the structure in question

func _init(struct, face, index, x, y, z):
	pos_x = x
	pos_y = y
	pos_z = z
	facing = face
	mesh_lib_index = index
	structure = struct

# Function to get every tile covered by a placed structure.
# # TODO: Might be able to work this in with builder::illegal_build_position by passing in a structure
# #   		and a position. Que sera sera
func get_cells(facing:Structure.Facings) -> Array[Vector3i]:
	var cells:Array[Vector3i] = []
	for dy in range(structure.y_size):
		for dz in range(structure.z_size):
			for dx in range(structure.x_size):
				var faced_dx = 0
				var faced_dz = 0
				if facing == structure.Facings.SW:
					faced_dx = dx
					faced_dz = -1 * dz
				elif facing == structure.Facings.SE:
					faced_dx = -1 * dz
					faced_dz = -1 * dx
				elif facing == structure.Facings.NE:
					faced_dx = -1 * dx
					faced_dz = dz
				else:
					faced_dx = dz
					faced_dz = dx 
				# Assumes structures are not concave - no L tetraminos.
				cells.append(Vector3i(pos_x + faced_dx, pos_y + dy, pos_z + faced_dz))
	return cells

# Gets the 'ortho basis' of the selector when this building was placed.
# Needed to replace buildings in gridmap when layers change
func get_ortho_basis_from_facing() -> int:
	# SW: 0 -> SW
	# SE: 16 -> SE
	# NE: 10 -> NE
	# NW: 22 -> NW
	if facing == Structure.Facings.SW:
		return 0
	elif facing == Structure.Facings.SE:
		return 16
	elif facing == Structure.Facings.NE:
		return 10
	else:
		return 22
