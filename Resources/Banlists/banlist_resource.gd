extends Resource

class_name BanlistResource

@export var name : String = ""
@export var cards : Dictionary[String, CardResource] = {}
@export var heroes : Dictionary[String, int] = {}

func clear_banlist() -> void:
	name = ""
	cards = {}
	heroes = {}
