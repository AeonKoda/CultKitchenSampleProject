class_name Recipe extends Resource

@export var index:int = 0
@export var tier:int = 1
@export var occult:bool = false
@export var uses_tool:bool = false
@export var tool:CardResource
@export var recipe:Array[CardResource]

@export_file var result_path:String

@export_custom(PROPERTY_HINT_NONE,"",PROPERTY_USAGE_READ_ONLY | PROPERTY_USAGE_EDITOR | PROPERTY_USAGE_STORAGE) var result_uid:int
