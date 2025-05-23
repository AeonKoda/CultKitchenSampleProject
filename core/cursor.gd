extends Control

@export var pointer:Texture
@export var can_lift:Texture
@export var dragging:Texture
@export var pinch:Texture
@export var augment:Texture
var is_dragging:bool = false
var is_hover:bool = false

@onready var cursor_icon: TextureRect = %CursorIcon
@onready var animated_cursor: AnimatedSprite2D = %AnimatedCursor

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED_HIDDEN)
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	TargetController.state_changed.connect(state_change)
	TargetController.cursor = self

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	position = get_viewport().get_mouse_position()

func _input(event: InputEvent) -> void:
	#if Input.is_action_pressed("augment"):
		#state_change()
		#return
	#if event.is_action_released("augment"):
		#state_change()
	if event.is_action_pressed("secondary_input") and TargetController.is_hovering() and not TargetController.is_holding():
		change_icon("hover_click")
	if (event.is_action_pressed("secondary_input") or event.is_action_pressed("primary_input"))and not TargetController.is_hovering() and not TargetController.is_holding():
		change_icon("pointer_click")
		

func state_change(state:TargetController.States)-> void:
	if state & TargetController.States.HOLD:
		change_icon("dragging")
	elif state & TargetController.States.HOVER:
		change_icon("can_lift")
	else:
		change_icon("pointer")

func change_icon(icon_name:String)-> void:
	#if animated_cursor.animation in ["hover_click","point_click"] and animated_cursor.is_playing():
		#if animated_cursor.animation_finished.is_connected(change_icon):
			#animated_cursor.animation_finished.disconnect(change_icon)
		#animated_cursor.animation_finished.connect(change_icon.bind(icon_name),4)
		#return
	animated_cursor.offset = Vector2.ZERO
	match icon_name:
		"pointer":
			animated_cursor.play("pointer")
		"can_lift":
			animated_cursor.play("hover")
		"dragging":
			animated_cursor.play("drag")
		"augment":
			animated_cursor.play("augment")
			animated_cursor.offset = Vector2(-6,-7)
		"hover_click":
			animated_cursor.stop()
			animated_cursor.play("hover_click")
		"pointer_click":
			animated_cursor.stop()
			animated_cursor.play("point_click")
