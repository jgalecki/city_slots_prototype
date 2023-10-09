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
		Structure.Types.Apartment:
			building_name_label.text = "Apartment"
		Structure.Types.CoffeeShop:
			building_name_label.text = "Coffee Shop"
		Structure.Types.TrainStation:
			building_name_label.text = "Train Station"
		Structure.Types.SmallPark:
			building_name_label.text = "Small Park"
		_:
			assert(false)
			
	match structure.rarity:
		Structure.Rarities.Common:
			building_rarity_label.text = "[center][b][color=gray]Common"
		Structure.Rarities.Uncommon:
			building_rarity_label.text = "[center][b][color=yellow]Uncommon"
		Structure.Rarities.Rare:
			building_rarity_label.text = "[center][b][color=red]Rare"
		_:
			assert(false)
			
	building_dimensions_label.text = "Dimensions: " + str(structure.x_size) + " x " + str(structure.z_size) + " x " + str(structure.y_size)
	building_income_label.text = str(structure.base_income)
	building_description_label.text = structure.description
	building_image.texture = structure.image
		
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_button_pressed():
	print(str(displayed_structure.type))
	building_chosen.emit(displayed_structure)
