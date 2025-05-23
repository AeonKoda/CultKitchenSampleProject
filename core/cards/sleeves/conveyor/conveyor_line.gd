class_name ConveyorLine extends Line2D

#[to-do] put this in the sleeve as a _draw function

var start_node:CanvasItem
var end_node:CanvasItem

var temp:bool = false
var temp_start:CanvasItem
var temp_end:CanvasItem

func _ready() -> void:
	if get_parent() is ConveyorButton:
		get_parent().line = self

func _process(_delta: float) -> void:
	if start_node and end_node and not temp:
		points = [Vector2.ZERO,end_node.global_position*global_transform]
	elif temp and temp_start and temp_end:
		points = [Vector2.ZERO,temp_end.global_position*global_transform]
