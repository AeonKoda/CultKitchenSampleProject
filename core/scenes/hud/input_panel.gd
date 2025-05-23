extends PanelContainer

@onready var input_show: Button = %InputShow
@onready var input_hide: Button = %InputHide
@onready var board_button: PanelContainer = %BoardButton
@onready var input_stack: VBoxContainer = %InputStack
@onready var advanced_button: Button = $MarginContainer/VBoxContainer2/AdvancedButton

var advanced:bool = true

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_on_button_pressed()
	
	input_hide.pressed.connect(_on_input_hide)
	input_show.pressed.connect(_on_input_show)
	if Global.game.show_input_help if Global.game else false:
		_on_input_show()
	else:
		_on_input_hide()


func _on_input_hide()-> void:
	input_show.show()
	hide()
	
	if Global.game: # To-do change this to signals
		Global.game.show_input_help = false
	
func _on_input_show()-> void:
	input_show.hide()
	show()
	
	if Global.game: # To-do change this to signals
		Global.game.show_input_help = true


func _on_button_pressed() -> void:
	advanced = !advanced
	advanced_button.text = "SHOW ADVANCED" if not advanced else "HIDE ADVANCED"
	
	for child:Control in input_stack.get_children().slice(4):
		child.visible = advanced
	
