extends Node

class_name JsonImporter

signal import_started
signal download_started
signal progress_string_changed
signal download_finished

var image_queue : Array[CardResource] = []
var image_paths : Dictionary[String, String] = {} # Maps image_url to file path
var flip_image_queue : Array[CardResource] = []
var flip_image_paths : Dictionary[String, String] = {} # Maps image_url to file path
var active_requests : int = 0
var active_flip_requests : int = 0
const MAX_CONCURRENT_FLIP_REQUESTS : int = 5
const MAX_CONCURRENT_REQUESTS : int = 40

const JSON_FILE_LOCATION : String = "res://Resources/Json/"
const SETS_JSON_FILE : String = "res://Resources/Json/sets.json"
const CARDS_JSON_FILE : String = "res://Resources/Json/card.json"
const PACK_FILE_LOCATION : String = "res://PackResources/"
const CARD_FILE_LOCATION : String = "res://CardResources/"
var importing_card_name : String = ""
var downloading_card_text : String = ""
var progress_string : String = ""

# Mapping of set_id to pack names
var set_id_to_pack_name : Dictionary[String, String] = {
	"WTR": "WelcomeToRathe",
	"ARC": "ArcaneRising",
	"CRU": "CrucibleOfWar",
	"MON": "Monarch",
	"ELE": "TalesOfAria",
	"EVR": "Everfest",
	"1HP": "HistoryPackOne",
	"UPR": "Uprising",
	"DYN": "Dynasty",
	"2HP": "HistoryPackTwo",
	"OUT": "Outsiders",
	"DTD": "DuskTillDawn",
	"EVO": "BrightLights",
	"HVY": "HeavyHitters",
	"MST": "PartTheMistveil",
	"ROS": "Rosetta",
	"HNT": "TheHunted",
	"SEA": "HighSeas",
	"SEA-TP": "TreasurePack",
	"MPG": "MasteryPackGuardian",
	"SUP": "SuperSlam",
	"PEN": "CompendiumOfRathe",
	"ANQ": "AntiquityPack"
}

# Gem pack ranges: each entry maps a card number range to a pack name
# Loaded from sets.json entries that have "starts" and "ends" fields
var gem_ranges : Array[Dictionary] = [] # [{starts: int, ends: int, pack_name: String}]

# Cache for loaded pack resources
var pack_resources_cache : Dictionary[String, PackResource] = {}
var sets_data : Dictionary = {}
var printings_by_unique_id : Dictionary = {}

func import_cards() -> void:
	import_started.emit()
	DirAccess.make_dir_absolute("res://PackResources")
	DirAccess.make_dir_absolute("user://BinderResources")
	DirAccess.make_dir_absolute("user://DeckResources")
	DirAccess.make_dir_absolute("res://CardResources")
	
	# Load sets configuration
	_load_sets_configuration()
	
	# Read cards.json
	var cards_file = FileAccess.open(CARDS_JSON_FILE, FileAccess.READ)
	if cards_file == null:
		push_error("Could not open cards.json")
		return
	
	var content = cards_file.get_as_text()
	cards_file.close()
	var cards_array : Array = JSON.parse_string(content)
	
	if cards_array == null:
		push_error("Failed to parse cards.json")
		return
	
	# Build a mapping of unique_id to printings for double-sided cards
	for card_json : Dictionary in cards_array:
		if card_json.has("printings"):
			for printing : Dictionary in card_json["printings"]:
				if printing.has("unique_id"):
					printings_by_unique_id[printing["unique_id"]] = {
						"card_json": card_json,
						"printing": printing
					}
	
	# Create a global cards directory
	var res_dir = DirAccess.open("res://")
	var global_cards_folder : String = CARD_FILE_LOCATION + "Cards/"
	if !res_dir.dir_exists(global_cards_folder):
		res_dir.make_dir(global_cards_folder)
	
	var global_images_folder : String = global_cards_folder + "Images/"
	if !res_dir.dir_exists(global_images_folder):
		res_dir.make_dir(global_images_folder)
	
	# Process each card (one resource per unique card)
	for card_json : Dictionary in cards_array:
		if !card_json.has("printings") or card_json["printings"].size() == 0:
			continue
		
		if !card_json.has("unique_id"):
			continue
		
		var card_unique_id : String = card_json["unique_id"]
		var card_resource_path : String = global_cards_folder + card_unique_id + ".res"
		
		# Skip if we've already created this card
		if FileAccess.file_exists(card_resource_path):
			continue
		
		# Sort printings by release date (earliest first) using sets_data
		var printings : Array = card_json["printings"].duplicate()
		printings.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
			var date_a : String = _get_printing_release_date(a)
			var date_b : String = _get_printing_release_date(b)
			return date_a < date_b
		)
		
		# Find the first valid printing with an image (now sorted by release date)
		var selected_printing : Dictionary = {}
		for printing : Dictionary in printings:
			if printing.has("image_url") and printing.get("image_url") != null:
				selected_printing = printing
				break
		
		# If no printing has an image, use the first printing
		if selected_printing.is_empty() and printings.size() > 0:
			selected_printing = printings[0]
		
		if selected_printing.is_empty():
			continue
		
		# Create the card resource
		var card_resource : CardResource = CardResource.new()
		_load_card_from_json(card_json, selected_printing, card_resource)
		
		# Handle double-sided cards
		if selected_printing.has("double_sided_card_info") and selected_printing["double_sided_card_info"].size() > 0:
			var dfc_info : Dictionary = selected_printing["double_sided_card_info"][0]
			if dfc_info.has("other_face_unique_id") and dfc_info.has("is_DFC") and dfc_info["is_DFC"]:
				var other_face_id : String = dfc_info["other_face_unique_id"]
				if printings_by_unique_id.has(other_face_id):
					var other_face_printing : Dictionary = printings_by_unique_id[other_face_id]["printing"]
					if other_face_printing.has("image_url"):
						card_resource.flip_image_url = other_face_printing["image_url"]
		
		progress_string = card_resource.name
		progress_string_changed.emit()
		
		# Handle card image
		if card_resource.image_url != "":
			if image_paths.has(card_resource.image_url):
				card_resource.image_path = image_paths.get(card_resource.image_url)
			else:
				card_resource.image_path = global_images_folder + card_unique_id + ".webp"
				image_paths[card_resource.image_url] = card_resource.image_path
				image_queue.append(card_resource)
		
		# Handle flip image if present
		if card_resource.flip_image_url != "":
			if flip_image_paths.has(card_resource.flip_image_url):
				card_resource.flip_image_path = flip_image_paths.get(card_resource.flip_image_url)
			else:
				card_resource.flip_image_path = global_images_folder + card_unique_id + "_FLIPPED.webp"
				flip_image_paths[card_resource.flip_image_url] = card_resource.flip_image_path
				flip_image_queue.append(card_resource)
		
		# Save card resource
		card_resource.resource_name = card_resource.name
		card_resource.resource_path = card_resource_path
		ResourceSaver.save(card_resource, card_resource.resource_path)
		
		# Now assign this card to all packs it appears in
		var assigned_packs : Dictionary = {} # Track which packs this card has been assigned to
		for printing : Dictionary in printings:
			if !printing.has("set_id"):
				continue
			
			var set_id : String = printing["set_id"]
			var pack_name : String = ""
			
			# Handle GEM cards specially using range-based resolution
			if set_id == "GEM" and printing.has("id"):
				pack_name = _resolve_gem_pack_name(printing["id"])
			elif set_id_to_pack_name.has(set_id):
				pack_name = set_id_to_pack_name[set_id]
			
			if pack_name == "":
				continue
			if assigned_packs.has(pack_name):
				continue
			assigned_packs[pack_name] = true
			
			var pack_resource : PackResource = _get_or_create_pack_resource(pack_name)
			
			# Load the card resource and assign to pack using printing-specific rarity/expansion
			var loaded_card : CardResource = ResourceLoader.load(card_resource_path)
			var printing_rarity : CardHelper.Rarity = CardHelper.Rarity.Common
			if printing.has("rarity"):
				printing_rarity = _parse_rarity(printing["rarity"])
			var printing_is_expansion : bool = false
			if printing.has("expansion_slot"):
				printing_is_expansion = printing["expansion_slot"]
			assign_card_to_pack(pack_resource, loaded_card, printing_rarity, printing_is_expansion)
		
		await get_tree().create_timer(0.00000000001).timeout
	
	# Save all pack resources
	for pack_name : String in pack_resources_cache:
		var pack_resource : PackResource = pack_resources_cache[pack_name]
		if pack_resource.resource_path != "" and pack_resource.resource_path != null:
			ResourceSaver.save(pack_resource, pack_resource.resource_path)
	
	_start_next_image_batch()
	_start_next_flip_image_batch()

func _load_sets_configuration() -> void:
	var sets_file = FileAccess.open(SETS_JSON_FILE, FileAccess.READ)
	if sets_file == null:
		push_error("Could not open sets.json")
		return
	
	var content = sets_file.get_as_text()
	sets_file.close()
	var sets_array : Array = JSON.parse_string(content)
	
	if sets_array == null:
		push_error("Failed to parse sets.json")
		return
	
	# Index sets by name and set_code
	for set_data : Dictionary in sets_array:
		if set_data.has("name"):
			sets_data[set_data["name"]] = set_data
		if set_data.has("set_code"):
			sets_data[set_data["set_code"]] = set_data
		
		# Build gem_ranges from entries with starts/ends fields
		if set_data.has("starts") and set_data.has("ends") and set_data.has("name"):
			var start_num : int = int(set_data["starts"].substr(3)) # e.g. "GEM001" -> 1
			var end_num : int = int(set_data["ends"].substr(3))     # e.g. "GEM035" -> 35
			gem_ranges.append({"starts": start_num, "ends": end_num, "pack_name": set_data["name"]})

func _get_or_create_pack_resource(pack_name: String) -> PackResource:
	# Check cache first
	if pack_resources_cache.has(pack_name):
		return pack_resources_cache[pack_name]
	
	var pack_file_path : String = PACK_FILE_LOCATION + pack_name + ".res"
	var pack_resource : PackResource = null
	
	# Try to load existing resource
	if FileAccess.file_exists(pack_file_path):
		pack_resource = ResourceLoader.load(pack_file_path)
	
	# Create new if doesn't exist
	if pack_resource == null:
		pack_resource = PackResource.new()
		pack_resource.resource_path = pack_file_path
		
		# Load configuration from sets.json
		if sets_data.has(pack_name):
			_configure_pack_from_sets_data(pack_resource, sets_data[pack_name])
		
		ResourceSaver.save(pack_resource, pack_resource.resource_path)
	
	# Cache it
	pack_resources_cache[pack_name] = pack_resource
	return pack_resource

func _resolve_gem_pack_name(printing_id: String) -> String:
	# Extract the number from a GEM printing ID like "GEM051" -> 51
	var num_str : String = printing_id.substr(3) # Strip "GEM" prefix
	if num_str == "":
		return ""
	var card_num : int = int(num_str)
	for gem_range : Dictionary in gem_ranges:
		if card_num >= gem_range["starts"] and card_num <= gem_range["ends"]:
			return gem_range["pack_name"]
	return ""

func _get_printing_release_date(printing: Dictionary) -> String:
	# Look up the release date for a printing via its set_id in sets_data
	if printing.has("set_id"):
		var set_id : String = printing["set_id"]
		var pack_name : String = ""
		if set_id == "GEM" and printing.has("id"):
			pack_name = _resolve_gem_pack_name(printing["id"])
		elif set_id_to_pack_name.has(set_id):
			pack_name = set_id_to_pack_name[set_id]
		if pack_name != "" and sets_data.has(pack_name):
			var set_data : Dictionary = sets_data[pack_name]
			if set_data.has("released_on"):
				return set_data["released_on"]
	return "9999-12-31" # Unknown sets sort last

func _configure_pack_from_sets_data(pack_resource: PackResource, set_data: Dictionary) -> void:
	if set_data.has("pack_enum"):
		pack_resource.pack_enum = set_data["pack_enum"]
	if set_data.has("number_of_cards"):
		pack_resource.number_of_cards = set_data["number_of_cards"]
	if set_data.has("pack_size"):
		pack_resource.pack_size = set_data["pack_size"]
	if set_data.has("released_on"):
		pack_resource.release_date = set_data["released_on"]
	
	# Load pull rates
	if set_data.has("pull_rates"):
		var pull_rates : Dictionary = set_data["pull_rates"]
		if pull_rates.has("foil_rare_rarity"):
			pack_resource.foil_rare_rarity = pull_rates["foil_rare_rarity"]
		if pull_rates.has("super_rare_rarity"):
			pack_resource.super_rare_rarity = pull_rates["super_rare_rarity"]
		if pull_rates.has("foil_super_rare_rarity"):
			pack_resource.foil_super_rare_rarity = pull_rates["foil_super_rare_rarity"]
		if pull_rates.has("majestic_rarity"):
			pack_resource.majestic_rarity = pull_rates["majestic_rarity"]
		if pull_rates.has("foil_majestic_rarity"):
			pack_resource.foil_majestic_rarity = pull_rates["foil_majestic_rarity"]
		if pull_rates.has("legendary_rarity"):
			pack_resource.legendary_rarity = pull_rates["legendary_rarity"]
		if pull_rates.has("marvel_rarity"):
			pack_resource.marvel_rarity = pull_rates["marvel_rarity"]
		if pull_rates.has("fabled_rarity"):
			pack_resource.fabled_rarity = pull_rates["fabled_rarity"]
		if pull_rates.has("expansion_slot_rarity"):
			pack_resource.expansion_slot_rarity = pull_rates["expansion_slot_rarity"]
	
	# Load pack contents
	if set_data.has("pack_contents"):
		var pack_contents : Dictionary = set_data["pack_contents"]
		if pack_contents.has("generics_commons_per_pack"):
			pack_resource.generics_commons_per_pack = pack_contents["generics_commons_per_pack"]
		if pack_contents.has("tokens_per_pack"):
			pack_resource.tokens_per_pack = pack_contents["tokens_per_pack"]
		if pack_contents.has("class_commons_per_pack"):
			pack_resource.class_commons_per_pack = pack_contents["class_commons_per_pack"]
		if pack_contents.has("guaranteed_rares_per_pack"):
			pack_resource.guaranteed_rares_per_pack = pack_contents["guaranteed_rares_per_pack"]
		if pack_contents.has("juicer_rares_per_pack"):
			pack_resource.juicer_rares_per_pack = pack_contents["juicer_rares_per_pack"]
		if pack_contents.has("equipment_per_pack"):
			pack_resource.equipment_per_pack = pack_contents["equipment_per_pack"]
		if pack_contents.has("non_token_premium_foil_per_pack"):
			pack_resource.non_token_premium_foil_per_pack = pack_contents["non_token_premium_foil_per_pack"]
		if pack_contents.has("expansion_slot_cards_per_pack"):
			pack_resource.expansion_slot_cards_per_pack = pack_contents["expansion_slot_cards_per_pack"]

func _load_card_from_json(card_json: Dictionary, printing: Dictionary, card_resource: CardResource) -> void:
	# Set print ID
	if printing.has("id"):
		card_resource.print_id = printing["id"]
		card_resource.id = printing["id"]
	
	# Basic card info
	if card_json.has("name"):
		card_resource.name = card_json["name"]
	if card_json.has("functional_text"):
		card_resource.card_effect = card_json["functional_text"]
	if card_json.has("color"):
		card_resource.color = card_json["color"]
	
	# Stats
	if card_json.has("pitch") and card_json["pitch"] != "":
		card_resource.pitch = int(card_json["pitch"])
	if card_json.has("cost") and card_json["cost"] != "":
		card_resource.cost = int(card_json["cost"])
	if card_json.has("defense") and card_json["defense"] != "":
		card_resource.defense = int(card_json["defense"])
	if card_json.has("power") and card_json["power"] != "":
		card_resource.power = int(card_json["power"])
	if card_json.has("intelligence") and card_json["intelligence"] != "":
		card_resource.intellect = int(card_json["intelligence"])
	if card_json.has("health") and card_json["health"] != "":
		card_resource.life = int(card_json["health"])
	if card_json.has("arcane") and card_json["arcane"] != "":
		card_resource.arcane = int(card_json["arcane"])
	
	# Image
	if printing.has("image_url") and printing.get("image_url") != null:
		card_resource.image_url = printing["image_url"]
	
	# Artist
	if printing.has("artists") and printing["artists"].size() > 0:
		card_resource.artist_name = printing["artists"][0]
	
	# Rarity from printing
	if printing.has("rarity"):
		var rarity_str : String = printing["rarity"]
		card_resource.rarity = _parse_rarity(rarity_str)
	
	# Expansion slot
	if printing.has("expansion_slot"):
		card_resource.is_expansion_slot = printing["expansion_slot"]
	
	# Parse types (includes classes, types, and subtypes)
	if card_json.has("types"):
		for type_str in card_json["types"]:
			var formatted_type : String = type_str.replace(" ", "_").replace("-", "_")
			# Handle special cases for 1H/2H
			if formatted_type == "1H" or formatted_type == "2H":
				formatted_type = "_" + formatted_type
			
			# Try to parse as class first
			if CardHelper.Class.keys().has(formatted_type):
				card_resource.classes.append(CardHelper.Class[formatted_type])
			# Then try as type
			elif CardHelper.Type.keys().has(formatted_type):
				card_resource.types.append(CardHelper.Type[formatted_type])
			# Finally try as subtype
			elif CardHelper.SubType.keys().has(formatted_type):
				card_resource.subtypes.append(CardHelper.SubType[formatted_type])
			elif CardHelper.Talent.keys().has(formatted_type):
				card_resource.talents.append(CardHelper.Talent[formatted_type])
	
	# Parse keywords
	if card_json.has("card_keywords"):
		for keyword_str in card_json["card_keywords"]:
			var formatted_keyword : String = keyword_str.replace(" ", "_").replace("-", "_")
			# Extract keyword name (before any numbers)
			var keyword_base : String = formatted_keyword.split(" ")[0]
			if CardHelper.Keyword.keys().has(keyword_base):
				card_resource.keywords.append(CardHelper.Keyword[keyword_base])

func _start_next_image_batch():
	download_started.emit()
	while active_requests < MAX_CONCURRENT_REQUESTS and image_queue.size() > 0:
		var card_resource : CardResource = image_queue.pop_front()
		var http_request = HTTPRequest.new()
		add_child(http_request)
		active_requests += 1
		http_request.request_completed.connect(_http_request_completed_batch.bind(card_resource, http_request))
		var error = http_request.request(card_resource.image_url)
		if error != OK:
			push_error("An error occurred in the HTTP request.")
			active_requests -= 1
	if image_queue.size() == 0 and active_requests == 0:
		download_finished.emit()

func _http_request_completed_batch(result, _response_code, _headers, body, card_resource, http_request):
	if result != HTTPRequest.RESULT_SUCCESS:
		push_error("Image couldn't be downloaded. Try a different image.")
	else:
		progress_string = card_resource.name
		progress_string_changed.emit()
		
		# Load image from buffer and save as JPEG
		var image = Image.new()
		var error = image.load_webp_from_buffer(body)
		if error != OK:
			error = image.load_png_from_buffer(body)
		
		if error == OK:
			# Save as JPEG with 0.85 quality (85% compression)
			image.save_webp(card_resource.image_path, true, 0.8)
		else:
			push_error("Failed to load image format for: " + card_resource.name)
	
	active_requests -= 1
	http_request.queue_free()
	_start_next_image_batch()
		
func _start_next_flip_image_batch():
	while active_flip_requests < MAX_CONCURRENT_FLIP_REQUESTS and flip_image_queue.size() > 0:
		var card_resource : CardResource = flip_image_queue.pop_front()
		var http_request = HTTPRequest.new()
		add_child(http_request)
		active_flip_requests += 1
		http_request.request_completed.connect(_flip_http_request_completed_batch.bind(card_resource, http_request))
		var error = http_request.request(card_resource.flip_image_url)
		if error != OK:
			push_error("An error occurred in the HTTP request.")
			active_flip_requests -= 1

func _flip_http_request_completed_batch(result, _response_code, _headers, body, card_resource, http_request):
	if result != HTTPRequest.RESULT_SUCCESS:
		push_error("Image couldn't be downloaded. Try a different image.")
	else:
		# Load image from buffer and save as JPEG
		var image = Image.new()
		var error = image.load_png_from_buffer(body)
		if error != OK:
			error = image.load_webp_from_buffer(body)
		if error != OK:
			error = image.load_jpg_from_buffer(body)
		
		if error == OK:
			# Save as JPEG with 0.85 quality (85% compression)
			image.save_jpg(card_resource.flip_image_path, 0.85)
		else:
			push_error("Failed to load flip image format for: " + card_resource.name)
	
	active_flip_requests -= 1
	http_request.queue_free()
	_start_next_flip_image_batch()
	
func assign_card_to_pack(pack_resource:PackResource, card_resource:CardResource, override_rarity : CardHelper.Rarity = CardHelper.Rarity.Common, override_is_expansion : bool = false) -> void:
	if override_is_expansion:
		pack_resource.expansion_slot_cards.append(card_resource)
		return

	match override_rarity:
		CardHelper.Rarity.Common:
			if card_resource.types.has(CardHelper.Type.Equipment):
				pack_resource.equipment_cards.append(card_resource)
			if card_resource.classes.has(CardHelper.Class.Generic) && pack_resource.generics_commons_per_pack > 0:
				pack_resource.generic_common_cards.append(card_resource)
			else:
				pack_resource.class_common_cards.append(card_resource)
		CardHelper.Rarity.Rare:
			if card_resource.types.has(CardHelper.Type.Equipment):
				pack_resource.equipment_cards.append(card_resource)
			else:
				pack_resource.rare_cards.append(card_resource)
		CardHelper.Rarity.Fabled:
			pack_resource.fabled_cards.append(card_resource)
		CardHelper.Rarity.Legendary:
			pack_resource.legendary_cards.append(card_resource)
		CardHelper.Rarity.Majestic:
			if card_resource.types.has(CardHelper.Type.Equipment) or card_resource.keywords.has(CardHelper.Keyword.Legendary):
				pack_resource.shortprint_majestic_cards.append(card_resource)
			else:
				pack_resource.majestic_cards.append(card_resource)
		CardHelper.Rarity.Super_Rare:
			pack_resource.super_rare_cards.append(card_resource)
		CardHelper.Rarity.Token:
			if card_resource.types.has(CardHelper.Type.Equipment):
				pack_resource.equipment_cards.append(card_resource)
			pack_resource.token_cards.append(card_resource)
		CardHelper.Rarity.Basic:
			pack_resource.token_cards.append(card_resource)
		CardHelper.Rarity.Marvel:
			pack_resource.marvel_cards.append(card_resource)
		CardHelper.Rarity.Promo:
			pack_resource.promo_cards.append(card_resource)

func clear_cards_and_packs() -> void:
	var dir_access := DirAccess.open("res://PackResources")
	
	for file in dir_access.get_files():
		if file.ends_with(".tres") or file.ends_with(".res"):
			var pack_resource : PackResource = ResourceLoader.load("res://PackResources/" + file)
			if pack_resource != null:
				pack_resource.clear_cards()
				ResourceSaver.save(pack_resource, pack_resource.resource_path)

func _parse_rarity(rarity_str: String) -> CardHelper.Rarity:
	# Map single-letter rarity codes to full names
	match rarity_str:
		"C":
			return CardHelper.Rarity.Common
		"R":
			return CardHelper.Rarity.Rare
		"S":
			return CardHelper.Rarity.Super_Rare
		"M":
			return CardHelper.Rarity.Majestic
		"L":
			return CardHelper.Rarity.Legendary
		"F":
			return CardHelper.Rarity.Fabled
		"T":
			return CardHelper.Rarity.Token
		"P":
			return CardHelper.Rarity.Promo
		_:
			return CardHelper.Rarity.Common
