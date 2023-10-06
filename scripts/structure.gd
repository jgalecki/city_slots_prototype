extends Resource
class_name Structure

enum Type { Empty, Apartment, TrainStation, CoffeeShop }
enum TypeFamily { Empty, Residential, Commercial, Transportation, Park, Industrial }
enum Rarity { Common, Uncommon, Rare }
enum Facing { SW, SE, NE, NW }

@export_subgroup("Model")
@export var model:PackedScene # Model of the structure
@export var image:Texture2D # Image / png of the structure

@export_subgroup("Gameplay")
@export var income:int # Base income level of the structure
@export var type:Type # Building type / title
@export var typeFamily:TypeFamily # Building type / title
@export var x_size:int # Typically length of the building
@export var z_size:int # Typically depth of the building
@export var y_size:int # Typically height of the building
@export var rarity:Rarity # Rarity of the building
@export_multiline var description:String # Description of the building

