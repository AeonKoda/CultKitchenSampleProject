extends Node2D

signal game_ready
signal card_created(card:Card)

const VIEWPORT_SIZE:Vector2 = Vector2(1280,720)

const DEFAULT_GRID_SIZE:int = 18
const SCREEN_MARGIN:float = 18.0

const land_cards:Array = ["FIELD","RICH_FIELD"]
const crop_cards:Array = ["DIRT","STONE","SUGARCANE","RICE","POTATO","WHEAT","CORN"]
const resource_cards:Array = ["CORN","WHEAT","SUGARCANE","RICE","POTATO","DIRT",
		"WATER","CORPSE_MUSHROOM"]
const animal_cards:Array = [
	"PIG","CHICKEN","COW","FISH","BLACK_CAT","TOAD","HUGE_TOAD",
	"COLOSSAL_TOAD",
	]

@export var grid_snap_always_on:bool = false

@export var card_scene:PackedScene
@export var recipe_resource:CardResource
@export var letter_resource:CardResource
@export var camera_scene:PackedScene

@export var door_resource:CardResource
@export var altar_resource:CardResource

@export var card_progress_bar_scene:PackedScene
@export var card_indicator_scene:PackedScene
@export var speech_bubble_scene:PackedScene

var game:Game
var camera:Camera2D

#ready
func _ready() -> void:
	camera = camera_scene.instantiate()
	camera.global_position = VIEWPORT_SIZE * Vector2(0.5,0.5)
	add_child(camera)
	


func create_card(card_resource:CardResource) -> Card:
	var new_card:Card = card_scene.instantiate()
	new_card.card_resource = card_resource
	card_created.emit(new_card)
	return new_card


func create_recipe(result_resource:CardResource) ->CardRecipe:
	var recipe_card:Card = create_card(recipe_resource.duplicate())
	recipe_card.card_resource.extended_class_resource = result_resource
	return recipe_card.check_change_type()


func create_letter(new_letter_resource:LetterResource) ->CardLetter:
	var letter_card:Card = create_card(letter_resource.duplicate())
	letter_card.card_resource.extended_class_resource = new_letter_resource
	
	return letter_card.check_change_type()


func pause()-> void:
	await get_tree().process_frame
	get_tree().set.call_deferred("paused",true)


func unpause()-> void:
	get_tree().paused = false
