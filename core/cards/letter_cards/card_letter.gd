class_name CardLetter extends Card
static func get_type_id()-> StringName:return &"CardLetter"
#
#
var occult_color:Color = Color("d5a5c4")
var scroll_amount:int = 118
var scroll_tween:Tween
var scroll_index:int = 0
var occult:bool = false:
	set(value):
		occult = value
		if value:
			texture.self_modulate = occult_color

var letter_resource:LetterResource

var recipe_container:MarginContainer

var recipe_label: RichTextLabel 
var recipe_scroll: ScrollContainer 
var recipe_indicator: TextureButton 
var indicator_h_box: HBoxContainer 

func _ready() -> void:
	super()
	if card_container:
		card_container.free()
	
	recipe_container = recipe_container_scene.instantiate()
	animation_container.add_child(recipe_container)
	
	recipe_label = recipe_container.recipe_label
	recipe_scroll = recipe_container.recipe_scroll
	recipe_indicator = recipe_container.recipe_indicator
	indicator_h_box = recipe_container.indicator_h_box
	#new_tag = recipe_container.new_tag
	title_label = recipe_container.title_label
	
	recipe_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	recipe_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	recipe_container.margin_container.add_theme_constant_override("margin_top",4)
	
	var texture_size:Vector2 = Vector2(140,100)
	size = texture_size
	texture.custom_minimum_size = texture_size
	texture.set_deferred("size",texture_size) # deferred these to avoid a warning about anchors
	
	texture.position = Vector2.ZERO # changing the minimum size moves the texture -13 y, don't know why
	# this resets the position to 0,0
	
	phantom_card.custom_minimum_size = texture_size
	phantom_card.set_deferred("size",texture_size)
	
	#if card_resource and card_resource.extended_class_resource:
		#letter_resource = card_resource.extended_class_resource
		#recipe_label.text = letter_resource.text
	
	
	
	
	if card_resource and card_resource.extended_class_resource:
		if card_resource.extended_class_resource is not LetterResource: 
			push_warning("Trying to load CardLetter with non LetterResource")
			return
		letter_resource = card_resource.extended_class_resource
		set_letter_text(letter_resource)
		#var result_path:String = ResourceUID.id_to_text(card_resource.extended_class_resource.result_uid)
		#
		#if FileAccess.file_exists(result_path):
			#result_resource = ResourceLoader.load(result_path)
		#else:
			#push_warning("CardResource result resource file path not found")
			#return
		occult = letter_resource.occult
		
		#if not Global.game.is_node_ready():
			#await  Global.game_ready
		
		#texture.gui_input.connect(_gui_input)
	
	#setup groups
	add_to_group("Letter")

func set_letter_text(letter_res:LetterResource)-> void:
	recipe_label.text = letter_res.text
	
	recipe_label.show() #hidden by default to populate recipe.
	
	if letter_res.type == LetterResource.LetterType.LETTER:
		title_label.text = str("[center]LETTER[/center]")
	elif letter_res.type == LetterResource.LetterType.GUIDE:
		title_label.text = str("[center]GUIDE[/center]")
	elif letter_res.snippet_owner:
		title_label.text = str("[center]",letter_res.snippet_owner.replace("_"," "),"[/center]")
	else:
		title_label.text = str("[center]???[/center]")

#func _gui_input(event: InputEvent) -> void:
	#if event.is_action_pressed("secondary_input"):
		#click()

#func click()->void:
	#if result_resource.recipes.size() > 1:
		#var indicator:TextureButton = indicator_h_box.get_child(scroll_index)
		#if scroll_index + 1 == indicator_h_box.get_child_count():
			#scroll_index = 0
		#else:
			#scroll_index += 1
		#
		#while indicator_h_box.get_child(scroll_index).disabled:
			#if scroll_index + 1 == indicator_h_box.get_child_count():
				#scroll_index = 0
			#else:
				#scroll_index += 1
		#
		#var final_val:int = scroll_index*scroll_amount
		#
		#if final_val != recipe_scroll.scroll_horizontal:
			#indicator.button_pressed = false
			#scroll_tween = create_tween()
			#scroll_tween.tween_property(recipe_scroll,"scroll_horizontal",final_val,0.4)
			#scroll_tween.finished.connect(func()->void:
				#recipe_scroll.scroll_horizontal = final_val
				#)
			#indicator = indicator_h_box.get_child(scroll_index)
			#indicator.button_pressed = true
		#else:
			#indicator_h_box.get_child(scroll_index+1).jitter()
#
#func make_recipe_text(card_recipe:Recipe)->String:
	#var recipe_text:String = ""
	#var tool:CardResource
	#
	#if card_recipe.uses_tool:
		#tool = card_recipe.tool
		#
	#recipe_text = str("[center]")
	#if tool:
		#recipe_text += str("<",tool.card_name.replace("_"," "),">\n")
		#
	#for reagent:CardResource in card_recipe.recipe:
		#var reagent_string:String = str(reagent.card_name.replace("_"," "))
		#recipe_text = recipe_text + str(reagent_string," + ")
	#
	#for reagent:CardResource in card_recipe.recipe:
		#var reagent_string:String = str(reagent.card_name.replace("_"," "))
		#var split:Array = recipe_text.split(str(reagent_string," + "))
		#var count:int = split.size() - 1
		#
		#if count > 1:
			#recipe_text = recipe_text.replace(str(reagent_string," + "),"")
			#recipe_text = recipe_text + str(count," x ",reagent_string," + ")
	#
	#recipe_text = recipe_text.trim_suffix(" + ")
	#recipe_text = recipe_text + str("[/center]")
	#return recipe_text
	#
#func get_recipe() ->String:
	###pass resource when card is created
	#var recipe_resource:CardResource = result_resource
	#var recipe_text:String = ""
	#if not recipe_resource.recipes.is_empty():
		#var recipes:Recipe = recipe_resource.recipes[0]
		#var recipe_list:Array = recipes.recipe
		#var tool:CardResource
		#if recipes.uses_tool:
			#tool = recipes.tool
			#
		#recipe_text = str("[center]")
		##var alpha:float = 0.5
		#if tool:
			##[bgcolor=%s]"%[Color(tool.color,alpha).to_html()][/bgcolor]
			#recipe_text += str("<",tool.card_name.replace("_"," "),">\n")
			#
		#for reagent:CardResource in recipe_list:
			##"[bgcolor=%s]"%[Color(reagent.color,alpha).to_html()],"[/bgcolor]",
			#recipe_text = recipe_text + str(reagent.card_name.replace("_"," ")," + ")
		#recipe_text = recipe_text.trim_suffix(" + ")
		#recipe_text = recipe_text + str("[/center]")
		#
	#return recipe_text
#
#func unlock_recipe(i:int)-> void:
	#new_tag.show()
	#var button:TextureButton = indicator_h_box.get_child(i)
	#button.disabled = false
	#
	#var final_val:int = i*scroll_amount
	#var indicator:TextureButton = indicator_h_box.get_child(scroll_index)
	#if final_val != recipe_scroll.scroll_horizontal:
		#indicator.button_pressed = false
		#scroll_tween = create_tween()
		#scroll_tween.tween_property(recipe_scroll,"scroll_horizontal",final_val,0.4)
		#scroll_tween.finished.connect(func()->void:
			#recipe_scroll.scroll_horizontal = final_val
		#)
		#indicator = indicator_h_box.get_child(scroll_index)
		#indicator.button_pressed = true
	
	##setup text and color
	#if letter:
		#occult = letter.occult
		#recipe_label.text = letter.text
		#recipe_label.show()
		#
		#if letter.type == Letter.LetterType.LETTER:
			#title_label.text = str("[center]LETTER[/center]")
		#elif letter.type == Letter.LetterType.GUIDE:
			#title_label.text = str("[center]GUIDE[/center]")
		#elif letter.snippet_owner:
			#title_label.text = str("[center]",letter.snippet_owner.replace("_"," "),"[/center]")
		#else:
			#title_label.text = str("[center]???[/center]")
	#elif result_resource:
