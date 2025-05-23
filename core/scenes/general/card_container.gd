@tool
class_name CardContainer extends FlowContainer

signal custom_size_changed

const card_size:Vector2 = Vector2(90,126)
@export var rows:int = 2:
	set(value):
		rows = value
		_resize()
@export var columns:int = 2:
	set(value):
		columns = value
		_resize()

@export var h_seperation:int = 22:
	set(value):
		h_seperation = value
		set_h_seperation_override(value)
@export var v_seperation:int = 22:
	set(value):
		v_seperation = value
		set_v_seperation_override(value)

var custom_size:Vector2 = Vector2(0,0)

func queue_resize()-> void:
	_resize.call_deferred()

func _resize()-> void:
	var width:float = (rows-1)*h_seperation + rows*card_size.x
	var height:float = (columns-1)*v_seperation + columns*card_size.y
	custom_size = Vector2(width,height)
	custom_minimum_size = Vector2(width,height)
	size = Vector2(width,height)
	custom_size_changed.emit(custom_size)

func set_h_seperation_override(value:int)-> void:
	add_theme_constant_override("h_separation",value)

func set_v_seperation_override(value:int)-> void:
	add_theme_constant_override("v_separation",value)
