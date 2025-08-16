extends Node

enum DeckType {
	ClassicConstructed,
	Blitz,
	UPF,
	ProjectBlue,
	Commoner
}

enum CardLocation {
	HERO_EQUIP,
	MAIN,
	INVENTORY,
	MAYBE,
	BANLIST,
	BINDER
}
var decks : Dictionary[String, DeckResource] = {}

func _ready():
	var thread : Thread = Thread.new()
	thread.start(load_decks)
	thread.wait_to_finish()

func load_decks() -> void:
	var dir = DirAccess.open("user://")
	if !dir.file_exists("user://DeckResources"):
		dir.make_dir("user://DeckResources")
	dir.change_dir("user://DeckResources")
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if file_name.ends_with(".res"):
			var deck_path = "user://DeckResources/" + file_name
			var deck = ResourceLoader.load(deck_path)
			if deck != null and deck.resource_name != "":
				decks[deck.resource_name] = deck
		file_name = dir.get_next()
	dir.list_dir_end()

func get_pretty_deck_type(deck_type : DeckHelper.DeckType) -> String:
	match deck_type:
		DeckHelper.DeckType.ClassicConstructed:
			return "Classic Constructed"
		DeckHelper.DeckType.ProjectBlue:
			return "Project Blue"
		_:
			return DeckHelper.DeckType.keys()[DeckType]
