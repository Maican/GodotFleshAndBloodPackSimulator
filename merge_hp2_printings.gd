@tool
extends EditorScript

## Merges HistoryPackTwo printings into card.json.
## All HP2 cards are reprints, so each HP2 entry becomes a new printing
## appended to the bottom of the matching card's "printings" array.
## Run via Script > Run in the Godot Editor.

const CARDS_JSON_PATH : String = "res://Resources/Json/card.json"
const HP2_JSON_PATH : String = "res://Resources/Json/10HistoryPackTwo_augmented.json"
const OUTPUT_JSON_PATH : String = "res://Resources/Json/card.json"

# Map HP2 text rarities to the single-letter codes used in card.json
var rarity_map : Dictionary = {
	"Common": "C",
	"Rare": "R",
	"Majestic": "M",
	"Legendary": "L",
	"Fabled": "F",
	"Token": "T",
	"Basic": "B",
	"Super Rare": "S",
	"Promo": "P",
}

# Map HP2 finishes to card.json foiling codes
var foiling_map : Dictionary = {
	"regular": "S",
	"rainbow-foil": "R",
	"cold-foil": "C",
	"gold-foil": "G",
}

func _run() -> void:
	print("=== Merging History Pack 2 printings into card.json ===")
	
	# Load card.json
	var cards_file := FileAccess.open(CARDS_JSON_PATH, FileAccess.READ)
	if cards_file == null:
		push_error("Could not open card.json")
		return
	var cards_content := cards_file.get_as_text()
	cards_file.close()
	var cards_array : Array = JSON.parse_string(cards_content)
	if cards_array == null:
		push_error("Failed to parse card.json")
		return
	print("Loaded card.json with %d cards" % cards_array.size())
	
	# Load HP2 JSON
	var hp2_file := FileAccess.open(HP2_JSON_PATH, FileAccess.READ)
	if hp2_file == null:
		push_error("Could not open HP2 JSON")
		return
	var hp2_content := hp2_file.get_as_text()
	hp2_file.close()
	var hp2_array : Array = JSON.parse_string(hp2_content)
	if hp2_array == null:
		push_error("Failed to parse HP2 JSON")
		return
	print("Loaded HP2 JSON with %d entries" % hp2_array.size())
	
	# Build a lookup: card name -> index in cards_array
	# Some cards share names across different colors, so we need name+color
	var card_lookup : Dictionary = {} # "name|color" -> index
	var card_name_only_lookup : Dictionary = {} # "name" -> [indices]
	for i in range(cards_array.size()):
		var card : Dictionary = cards_array[i]
		var name : String = card.get("name", "")
		var color : String = card.get("color", "")
		var key : String = name + "|" + color
		card_lookup[key] = i
		if !card_name_only_lookup.has(name):
			card_name_only_lookup[name] = []
		card_name_only_lookup[name].append(i)
	
	# Map HP2 color info: HP2 entries with the same name but different print IDs
	# represent different color variants (Red/Yellow/Blue).
	# We need to figure out which color each HP2 entry maps to.
	# The HP2 data doesn't have an explicit color field, so we match by name
	# and assign to card.json entries in order of their existing colors.
	
	# Group HP2 entries by name
	var hp2_by_name : Dictionary = {} # name -> [hp2_entries]
	for hp2_entry : Dictionary in hp2_array:
		var name : String = hp2_entry.get("name", "")
		if !hp2_by_name.has(name):
			hp2_by_name[name] = []
		hp2_by_name[name].append(hp2_entry)
	
	var merged_count : int = 0
	var skipped_count : int = 0
	var not_found_names : Array = []
	
	for hp2_name : String in hp2_by_name:
		var hp2_entries : Array = hp2_by_name[hp2_name]
		
		if !card_name_only_lookup.has(hp2_name):
			not_found_names.append(hp2_name)
			skipped_count += hp2_entries.size()
			continue
		
		var card_indices : Array = card_name_only_lookup[hp2_name]
		
		# Sort HP2 entries by print_id to get consistent ordering
		hp2_entries.sort_custom(func(a, b):
			var a_id : String = a["prints"][0]["print_id"] if a["prints"].size() > 0 else ""
			var b_id : String = b["prints"][0]["print_id"] if b["prints"].size() > 0 else ""
			return a_id < b_id
		)
		
		# Sort card indices by color for consistent matching (Red, Yellow, Blue)
		var color_order : Dictionary = {"Red": 0, "Yellow": 1, "Blue": 2, "": 3}
		card_indices.sort_custom(func(a, b):
			var color_a : String = cards_array[a].get("color", "")
			var color_b : String = cards_array[b].get("color", "")
			var order_a : int = color_order.get(color_a, 99)
			var order_b : int = color_order.get(color_b, 99)
			return order_a < order_b
		)
		
		if hp2_entries.size() == card_indices.size():
			# 1-to-1 mapping: each HP2 entry maps to a card variant
			for j in range(hp2_entries.size()):
				var hp2_entry : Dictionary = hp2_entries[j]
				var card_idx : int = card_indices[j]
				_append_printing(cards_array[card_idx], hp2_entry)
				merged_count += 1
		elif hp2_entries.size() == 1 and card_indices.size() >= 1:
			# Single HP2 entry, possibly multiple card variants (e.g. equipment)
			# Add to the first matching card
			var hp2_entry : Dictionary = hp2_entries[0]
			var card_idx : int = card_indices[0]
			_append_printing(cards_array[card_idx], hp2_entry)
			merged_count += 1
		elif hp2_entries.size() < card_indices.size():
			# Fewer HP2 entries than card variants, match what we can
			for j in range(hp2_entries.size()):
				var hp2_entry : Dictionary = hp2_entries[j]
				var card_idx : int = card_indices[j]
				_append_printing(cards_array[card_idx], hp2_entry)
				merged_count += 1
		else:
			# More HP2 entries than card variants - shouldn't happen for reprints
			# but handle gracefully: assign extras to the last card
			for j in range(hp2_entries.size()):
				var hp2_entry : Dictionary = hp2_entries[j]
				var card_idx : int = card_indices[min(j, card_indices.size() - 1)]
				_append_printing(cards_array[card_idx], hp2_entry)
				merged_count += 1
	
	print("Merged %d printings" % merged_count)
	print("Skipped %d entries" % skipped_count)
	if not_found_names.size() > 0:
		print("Cards not found in card.json:")
		for n in not_found_names:
			print("  - %s" % n)
	
	# Write the updated card.json
	var output_file := FileAccess.open(OUTPUT_JSON_PATH, FileAccess.WRITE)
	if output_file == null:
		push_error("Could not open output file for writing")
		return
	output_file.store_string(JSON.stringify(cards_array, "\t"))
	output_file.close()
	
	print("=== Done! Wrote updated card.json with %d cards ===" % cards_array.size())

func _append_printing(card: Dictionary, hp2_entry: Dictionary) -> void:
	if !card.has("printings"):
		card["printings"] = []
	
	# Build printing(s) from HP2 entry - one per print in the prints array
	for hp2_print : Dictionary in hp2_entry.get("prints", []):
		var printing : Dictionary = {}
		
		# Convert print_id: strip "FR_" prefix, e.g. "FR_2HP001" -> "2HP001"
		var raw_id : String = hp2_print.get("print_id", "")
		var clean_id : String = raw_id
		if clean_id.begins_with("FR_"):
			clean_id = clean_id.substr(3)
		printing["id"] = clean_id
		
		# Set ID is always 2HP
		printing["set_id"] = "2HP"
		
		# Rarity
		var rarity_text : String = hp2_entry.get("rarity", "Common")
		printing["rarity"] = rarity_map.get(rarity_text, "C")
		
		# Foiling - derive from finishes
		var finishes : Array = hp2_entry.get("finishes", [])
		if finishes.size() > 0:
			printing["foiling"] = foiling_map.get(finishes[0], "S")
		else:
			printing["foiling"] = "S"
		
		# Edition
		printing["edition"] = "N"
		
		# Expansion slot - HP2 cards are not expansion slot
		printing["expansion_slot"] = false
		
		# Artist
		var artist : String = hp2_entry.get("artist", "")
		if artist != "":
			printing["artists"] = [artist]
		else:
			printing["artists"] = []
		
		# Image URL from HP2
		var image_dict : Dictionary = hp2_entry.get("image", {})
		var image_url : String = image_dict.get("large", image_dict.get("normal", ""))
		if image_url != "":
			printing["image_url"] = image_url
		
		# Optional fields with defaults
		printing["art_variations"] = []
		printing["flavor_text"] = ""
		printing["flavor_text_plain"] = ""
		printing["image_rotation_degrees"] = 0
		
		# Append at the bottom of printings so existing images take priority
		card["printings"].append(printing)
