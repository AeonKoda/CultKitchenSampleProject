class_name Component extends Node
var entity:Control:
	set(value):
		entity = value

func _enter_tree() -> void:
	name = get_script().get_global_name()
	if get_parent() is Control:
		entity = get_parent()
	else:
		push_warning(get_script().get_global_name()," child of ",get_parent()," is not child of Contorl Node")
		set_script.call_deferred(null)
		return
	if not entity.has_meta(get_script().get_global_name()):
		entity.set_meta(get_script().get_global_name(),self)

func _exit_tree() -> void:
	if entity and entity.has_meta(get_script().get_global_name()):
		entity.remove_meta(get_script().get_global_name())

func _ready() -> void:
	if get_tree().root.get_node_or_null("ComponentEventCoordinator"):
		ComponentEventCoordinator.component_ready(self)

	if entity.has_signal("card_queued_free"):
		if not entity.is_connected("card_queued_free",release):
			entity.connect("card_queued_free",release.unbind(1))

func release()->void:
	queue_free()

static func get_component_or_null(s_entity:Control,component_type_id:StringName)-> Variant:
	if not s_entity:
		return null
	
	if s_entity.has_meta(component_type_id):
		return s_entity.get_meta(component_type_id)
	return null
