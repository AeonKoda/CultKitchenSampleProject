class_name CardResource extends Resource

enum TYPES {
	CARD,
	RECIPE,
	SLEEVE,
	LETTER
}

static func get_type_class_name(type:TYPES)-> StringName:
	match type:
		TYPES.CARD:
			return Card.get_type_id()
		TYPES.RECIPE:
			return CardRecipe.get_type_id()
		TYPES.SLEEVE:
			return CardSleeve.get_type_id()
		TYPES.LETTER:
			return CardLetter.get_type_id()
		_:
			return &""
		
@export_group("Card")
@export var card_name:String
@export var unique_prime_identifier:int
@export var text_color:Color = Color.BLACK
@export var color:Color
@export var art_texture:Texture
@export var alternate_art_texture:Texture
@export var rare_alt:bool

@export var recipes:Array[Recipe]
@export_subgroup("GameStates")
@export var value:float = 0.0
@export var sellable:bool = true
@export var has_speech:bool = false
@export var occult:bool = false
@export var can_burn:bool = true
@export var meal:bool = false
@export var meal_level:int = 1

@export_group("ExtendedClass")
@export var extended_class:TYPES = TYPES.CARD
@export var extended_class_resource:Resource

@export_group("Actions")
@export var progress_max_value:int
@export var one_shot:bool
@export var locked:bool
@export var fuel_cards:Array[CardResource]
@export var spawn_cards:Array[CardResource] #= []
@export var spawn_recipes:Array[CardResource] #= []
@export var spawn_letters:Array[LetterResource] #= []

@export_subgroup("Clicker")
@export var clicker:bool
@export var click_action:Script

@export_subgroup("Ticker")
@export var ticker:bool
@export var auto_on:bool = false
@export var disable_control:bool = false
@export var tick_action:Script
@export var tick_speed:float = 1

@export_group("Board")
@export var board:bool = false:
	set(value):
		board = value
		if value:
			board_lock = value

@export var board_lock:bool = false:
	set(value):
		board_lock = value
		if board:
			board_lock = true

@export_subgroup("Ritual Cirlce")
@export var creation_effect:PackedScene
@export var ritual_circle:bool = false
@export var salts:int = 2

@export_subgroup("Storage")
@export var is_storage:bool = false
@export var max_storage:int
