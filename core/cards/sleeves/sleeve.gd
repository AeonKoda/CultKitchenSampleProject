class_name Sleeve extends MarginContainer


var entity:Control
var sleeved_card:Card
var sleeve_resource:SleeveResource

func setup(item:Control,resource:SleeveResource)-> void:
	entity = item
	sleeve_resource = resource
	pivot_offset = entity.size/2

func sleeved(_card:Card)-> void:
	pass

func unsleeved()-> void:
	position = Vector2.ZERO
