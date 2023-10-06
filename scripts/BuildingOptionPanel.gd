extends PanelContainer

class_name BuildingOptionsPanel

@export var building_name_label:Label
@export var building_rarity_label:RichTextLabel	
@export var building_dimensions_label:Label
@export var building_income_label:Label
@export var building_description_label:RichTextLabel	
@export var building_image:TextureRect
@export var build_button:Button

signal building_chosen(building:Structure)

var displayed_structure:Structure

func set_option(structure:Structure):
	displayed_structure = structure
	
	match structure.type:
		Structure.Type.Apartment:
			building_name_label.text = "Apartment"
		Structure.Type.CoffeeShop:
			building_name_label.text = "Coffee Shop"
		Structure.Type.TrainStation:
			building_name_label.text = "Train Station"
		_:
			assert(false)
			
	match structure.rarity:
		Structure.Rarity.Common:
			building_rarity_label.text = "[center][b][color=gray]Common"
		Structure.Rarity.Uncommon:
			building_rarity_label.text = "[center][b][color=yellow]Uncommon"
		Structure.Rarity.Rare:
			building_rarity_label.text = "[center][b][color=red]Rare"
		_:
			assert(false)
			
	building_dimensions_label.text = "Dimensions: " + str(structure.x_size) + " x " + str(structure.z_size) + " x " + str(structure.y_size)
	building_income_label.text = str(structure.income)
	building_description_label.text = structure.description
	building_image.texture = structure.image
	
	# set button signal to be structure
	build_button.pressed.connect(self._on_button_press)
	
func _on_button_press():
	print(str(displayed_structure.type))
	building_chosen.emit(displayed_structure)
		
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
