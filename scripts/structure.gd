extends Resource
class_name Structure

enum Types { Empty, Apartment, TrainStation, CoffeeShop, SmallPark }
enum Families { Empty, Residential, Commercial, Transportation, Park, Industrial }
enum Rarities { Common, Uncommon, Rare }
enum Facings { SW, SE, NE, NW }

@export_subgroup("Model")
@export var model:PackedScene # Model of the structure
@export var image:Texture2D # Image / png of the structure

@export_subgroup("Gameplay")
@export var base_income:int # Base income level of the structure
@export var type:Types # Building type / title
@export var typeFamily:Families # Building type / title
@export var x_size:int # Typically length of the building
@export var z_size:int # Typically depth of the building
@export var y_size:int # Typically height of the building
@export var rarity:Rarities # Rarity of the building
@export_multiline var description:String # Description of the building
@export var symbols:Array[Symbol]

