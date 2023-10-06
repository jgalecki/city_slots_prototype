extends Control

class_name SlotsTile

@export var background_tile_image:TextureRect
@export var symbol_image:TextureRect

@export var cash_group:Control
#@export var cash_image:TextureRect
@export var cash_label:Label


@export var tile_commercial:Texture2D
@export var tile_residential:Texture2D
@export var tile_park:Texture2D
@export var tile_industrial:Texture2D
@export var tile_transportation:Texture2D

func set_no_symbol():
	symbol_image.visible = false
	
func set_symbol(symbol:Symbol):
	symbol_image.visible = true
	symbol_image.texture = symbol.image
	
# NOTE TO SELF - make sure this stays aligned with the editor setting Structures in Builder / CityScreen 
func set_background_tile_to_building(building_type:Structure.TypeFamily):
	match building_type:
		Structure.TypeFamily.Empty:
			background_tile_image.visible = false
		Structure.TypeFamily.Residential:
			background_tile_image.visible = true
			background_tile_image.texture = tile_residential
		Structure.TypeFamily.Commercial:
			background_tile_image.visible = true
			background_tile_image.texture = tile_commercial
		Structure.TypeFamily.Industrial:
			background_tile_image.visible = true
			background_tile_image.texture = tile_industrial
		Structure.TypeFamily.Park:
			background_tile_image.visible = true
			background_tile_image.texture = tile_park
		Structure.TypeFamily.Transportation:
			background_tile_image.visible = true
			background_tile_image.texture = tile_transportation
		_:
			assert(false)

func set_cash_label(structure:Structure):
	if structure.income == 0:
		cash_group.visible = false
		return
	
	cash_group.visible = true
	cash_label.text = "x" + str(structure.income)
