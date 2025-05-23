class_name HUD extends CanvasLayer

signal shop_button_pressed
signal side_storage_button_pressed
signal entity_dropped_on_side_storage_button
signal board_button_pressed(index:int)

@onready var board_depth: HBoxContainer = %BoardDepth
@onready var board_button: PanelContainer = %BoardButton

@onready var shop_button: TextureButton = %ShopButton

@onready var gold_label: Label = %GoldLabel
@onready var pig: Pig = %Pig


func _ready() -> void:
	shop_button.pressed.connect(_on_shop_button_pressed)

func set_gold(value:int)-> void:
	gold_label.text = str(value,"G")

func reduce_board_buttons_to_size(num:int)-> void:
	num = max(0,num)
	
	var child_count:int = board_depth.get_child_count()
	if child_count <= num: return
	
	while child_count > num:
		board_depth.get_child(child_count-1).queue_free()
		child_count -= 1

func add_board_button(board_name:String, board_color:Color, font_color:Color)-> void:
	var new_board_button:PanelContainer = board_button.duplicate()
	var input:Button = new_board_button.get_child(0)
	input.text = board_name
	input.self_modulate = board_color
	input.add_theme_color_override("font_color",font_color)
	input.add_theme_color_override("font_hover_color",font_color)
	input.add_theme_color_override("font_pressed_color",font_color)
	new_board_button.show()
	
	input.pressed.connect(_on_board_button_pressed.bind(new_board_button))
	board_depth.add_child(new_board_button)

func _on_board_button_pressed(button:PanelContainer)-> void:
	var index:int =  button.get_index()
	board_button_pressed.emit(index)

func _on_shop_button_pressed()-> void:
	shop_button_pressed.emit()

func _on_side_storage_button_pressed()-> void:
	side_storage_button_pressed.emit()

func _on_entity_dropped_on_side_storage_button(entity:Control)-> void:
	entity_dropped_on_side_storage_button.emit(entity)
	
