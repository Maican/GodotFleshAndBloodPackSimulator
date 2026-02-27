extends Node

## CardDatabase is an autoload that indexes all CardResource files by their unique ID.
## This allows user data (binders, decks, banlists) to store only card IDs (strings),
## which survive program updates that re-generate CardResource .res files.

var cards : Dictionary[String, CardResource] = {}
var _loaded : bool = false

const CARD_RESOURCES_PATH : String = "res://CardResources/Cards/"

func _ready() -> void:
	_load_all_cards()

func _load_all_cards() -> void:
	cards.clear()
	var dir := DirAccess.open(CARD_RESOURCES_PATH)
	if dir == null:
		push_warning("CardDatabase: Could not open " + CARD_RESOURCES_PATH)
		return

	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.ends_with(".res"):
			var path : String = CARD_RESOURCES_PATH + file_name
			var card : CardResource = ResourceLoader.load(path)
			if card != null and card.id != "":
				cards[card.id] = card
		file_name = dir.get_next()
	dir.list_dir_end()
	_loaded = true
	print("CardDatabase: Loaded " + str(cards.size()) + " cards")

## Look up a CardResource by its unique ID. Returns null if not found.
func get_card(id : String) -> CardResource:
	if cards.has(id):
		return cards[id]
	push_warning("CardDatabase: Card not found: " + id)
	return null

## Check if a card ID exists in the database.
func has_card(id : String) -> bool:
	return cards.has(id)

## Get all loaded card IDs.
func get_all_card_ids() -> Array[String]:
	var ids : Array[String] = []
	ids.assign(cards.keys())
	return ids

## Get all loaded CardResources.
func get_all_cards() -> Array[CardResource]:
	var result : Array[CardResource] = []
	result.assign(cards.values())
	return result
