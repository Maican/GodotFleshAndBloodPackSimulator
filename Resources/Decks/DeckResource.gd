extends Resource

class_name DeckResource

@export var name : String = "Deck"
@export var hero : CardResource
#CardName Key - [quantity, card_resource]
@export var main_equipment : Dictionary[String, Array] = {}
@export var main_deck : Dictionary[String, Array] = {}
@export var inventory : Dictionary[String, Array] = {}
@export var maybes : Dictionary[String, Array] = {}
@export var deck_type : DeckHelper.DeckType = DeckHelper.DeckType.ClassicConstructed

func export_deck() -> String:
	return "export deck"

func clear_deck() -> void:
	main_equipment = {}
	main_deck = {}
	inventory = {}
	maybes = {}
	hero = null
