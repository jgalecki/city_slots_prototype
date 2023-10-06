extends Resource

class_name Symbol

enum Types { Coffee, Barrels, Empty }
enum Families { Food, Goods, Culture, Empty }

@export var image:Texture2D # Image / png of the structure
@export var type:Types
@export var family:Families
@export var value:int
