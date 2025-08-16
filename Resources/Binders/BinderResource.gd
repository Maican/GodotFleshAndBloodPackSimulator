extends Resource

class_name BinderResource

@export var cards : Dictionary[String, Array] = {}
@export var name : String = ""

func clear_binder() -> void:
	cards = {}
