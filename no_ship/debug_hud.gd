class_name DebugHUD extends CanvasLayer

signal skip_tutorial_pressed

@onready var debug_info: VBoxContainer = %DebugInfo
@onready var info_lables: HBoxContainer = %InfoLables

@onready var debug_options: VBoxContainer = %DebugOptions
@onready var debug_option: HBoxContainer = %DebugOption
@onready var tutorial_button: Button = %TutorialButton



var debug_variables:Array = [
	{"name":"Current target", "callable":"_target","show":true},
	{"name":"Current special target", "callable":"special_area_target","show":false},
	{"name":"Current held entities", "callable":"held_entities","show":false},
	{"name":"Current target state", "callable":"state","show":false},
]

func _ready() -> void:
	for i:int in debug_variables.size():
		var new_info:HBoxContainer = info_lables.duplicate()
		new_info.get_child(0).text = debug_variables[i]["name"] + ": "
		debug_info.add_child(new_info)
		
		
		var new_option:HBoxContainer = debug_option.duplicate()
		new_option.get_child(1).text = debug_variables[i]["name"]
		var check:CheckBox = new_option.get_child(0)
		check.button_pressed = debug_variables[i]["show"]
		check.toggled.connect(set_vis.bind(i))
		debug_options.add_child(new_option)
	info_lables.queue_free()
	debug_option.queue_free()

func _process(_delta: float) -> void:
	var labels:Array = debug_info.get_children()
	for i:int in labels.size():
		var label:HBoxContainer = labels[i]
		label.get_child(1).text = str(TargetController.get(debug_variables[i]["callable"]))
		label.visible = debug_variables[i]["show"]

func set_vis(value:bool,index:int)-> void:
	debug_variables[index]["show"] = value


func _on_button_pressed() -> void:
	$PanelContainer.visible = !$PanelContainer.visible


func _on_button_2_pressed() -> void:
	skip_tutorial_pressed.emit()
	tutorial_button.hide()
