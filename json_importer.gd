extends Node

class_name JsonImporter

signal import_started
signal download_started
signal progress_string_changed
signal download_finished

var image_queue : Array[CardResource] = []
var image_paths : Dictionary[String, String] = {}
var flip_image_queue : Array[CardResource] = []
var flip_image_paths : Dictionary[String, String] = {}
var active_requests : int = 0
var active_flip_requests : int = 0
const MAX_CONCURRENT_FLIP_REQUESTS : int = 5
const MAX_CONCURRENT_REQUESTS : int = 40

const JSON_FILE_LOCATION : String = "res://Resources/Json/Sets/"
const PACK_FILE_LOCATION : String = "res://PackResources/"
const CARD_FILE_LOCATION : String = "res://CardResources/"
var importing_card_name : String = ""
var downloading_card_text : String = ""
var progress_string : String = ""
func import_cards() -> void:
	import_started.emit()
	DirAccess.make_dir_absolute("res://PackResources")
	DirAccess.make_dir_absolute("user://BinderResources")
	DirAccess.make_dir_absolute("user://DeckResources")
	DirAccess.make_dir_absolute("res://CardResources")
	var pack_resources_dir : DirAccess = DirAccess.open(PACK_FILE_LOCATION)
	var pack_file_name_array : Array = pack_resources_dir.get_files()
	pack_file_name_array.erase("HistoryPackTwo.res")
	pack_file_name_array.erase("HistoryPackOne.res")
	pack_file_name_array.erase("GemPack1.res")
	pack_file_name_array.erase("GemPack2.res")
	pack_file_name_array.append("HistoryPackOne.res")
	pack_file_name_array.append("HistoryPackTwo.res")
	pack_file_name_array.append("GemPack1.res")
	pack_file_name_array.append("GemPack2.res")
	for pack_file_name : String in pack_file_name_array:
		var res_dir = DirAccess.open("res://")
		if !pack_file_name.ends_with(".res"):
			continue
		var pack_resource : PackResource = ResourceLoader.load(PACK_FILE_LOCATION + pack_file_name)
		if pack_resource == null:
			print("Can't load pack resource for " + PACK_FILE_LOCATION + pack_file_name)
			continue
		var dir_folder : String = CARD_FILE_LOCATION + pack_file_name.replace(".res", "") + "/"
		if !res_dir.dir_exists(dir_folder):
			res_dir.make_dir(dir_folder)
			
		var dir_image_folder : String = CARD_FILE_LOCATION + pack_file_name.replace(".res", "") + "/Images/"
		if !res_dir.dir_exists(dir_image_folder):
			res_dir.make_dir(dir_image_folder)
			
		var json_dir : DirAccess = DirAccess.open(JSON_FILE_LOCATION)
		for file_name : String in json_dir.get_files():
			if !file_name.ends_with("augmented.json"):
				continue
			if file_name.find(pack_file_name.replace(".res", "")) == -1:
				continue
			var file = FileAccess.open(json_dir.get_current_dir() + "/" + file_name, FileAccess.READ)
			var content = file.get_as_text()
			var json_array : Array = JSON.parse_string(content)
			
			for json : Dictionary in json_array:
				var card_resource : CardResource = CardResource.new()
				load_json_into_card(json, card_resource)
				if card_resource.classes.size() == 0:
					print("SKIPPED: " + card_resource.id + " " + card_resource.print_id)
					continue
				progress_string = card_resource.name
				progress_string_changed.emit()
				
				#If we've already downloaded this card's image.
				#NOTE: This does remove alternate arts as a concept.
				if image_paths.has(card_resource.id):
					card_resource.image_path = image_paths.get(card_resource.id)
				else:
					# Save to file
					card_resource.image_path = dir_image_folder + card_resource.id + ".webp"
					image_paths[card_resource.id] = card_resource.image_path
					image_queue.append(card_resource)
					
				if !card_resource.flip_image_url.is_empty():
					if flip_image_paths.has(card_resource.id):
						card_resource.flip_image_path = flip_image_paths.get(card_resource.id)
					else:
						# Save to file
						card_resource.flip_image_path = dir_image_folder + card_resource.id + "_FLIPPED.webp"
						flip_image_paths[card_resource.id] = card_resource.flip_image_path
						flip_image_queue.append(card_resource)
					
				if card_resource.unique_set_print_ids.size() == 1:
					card_resource.resource_name = card_resource.name
					card_resource.resource_path = dir_folder + card_resource.print_id + ".res"
					ResourceSaver.save(card_resource, card_resource.resource_path)
					assign_card_to_pack(pack_resource, card_resource)
				else:
					for set_number : int in card_resource.unique_set_print_ids:
						var print_id : String = card_resource.unique_set_print_ids[set_number]
						if !FileAccess.file_exists(dir_folder + print_id + ".res"):
							card_resource.resource_name = card_resource.name
							card_resource.resource_path = dir_folder + print_id + ".res"
							ResourceSaver.save(card_resource, card_resource.resource_path)
							assign_card_to_pack(pack_resource, card_resource)
					
				await get_tree().create_timer(0.00000000001).timeout
		if pack_resource.resource_path != "" and pack_resource.resource_path != null:
			ResourceSaver.save(pack_resource, pack_resource.resource_path)
	_start_next_image_batch()
	_start_next_flip_image_batch()

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
	progress_string = card_resource.name
	progress_string_changed.emit()
	var file = FileAccess.open(card_resource.image_path, FileAccess.WRITE)
	file.store_buffer(body)
	file.close()
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
	var file = FileAccess.open(card_resource.flip_image_path, FileAccess.WRITE)
	file.store_buffer(body)
	file.close()
	active_flip_requests -= 1
	http_request.queue_free()
	_start_next_flip_image_batch()
	
func assign_card_to_pack(pack_resource:PackResource, card_resource:CardResource) -> void:
	if card_resource.is_expansion_slot:
		pack_resource.expansion_slot_cards.append(card_resource)
		return

	match card_resource.rarity:
		CardHelper.Rarity.Common:
			if card_resource.types.has(CardHelper.Type.Equipment):
				pack_resource.equipment_cards.append(card_resource)
			if card_resource.classes.has(CardHelper.Class.Generic):
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
		if file.ends_with(".tres"):
			var pack_resource : PackResource = ResourceLoader.load("res://PackResources//" + file)
			pack_resource.clear_cards()
			ResourceSaver.save(pack_resource, pack_resource.resource_path)

func load_json_into_card(json:Dictionary, card_resource:CardResource) -> void:
	if json.has("card_id"):
		card_resource.id = json.get("card_id")
	if json.has("prints"):
		var prints_array : Array = json.get("prints")
		if prints_array.size() > 0:
			var print_id : String = prints_array[0].get("print_id")
			if print_id.begins_with("ART"):
				return
			card_resource.print_id = print_id
			for printing : Dictionary in prints_array:
				print_id = printing.get("print_id")
				var set_number : int = printing.get("set_number")
				if !card_resource.unique_set_print_ids.has(set_number):
					card_resource.unique_set_print_ids[set_number] = print_id
		else:
			print("No prints for " + card_resource.id)
	if json.has("display_name"):
		card_resource.name = json.get("display_name")
	for class_string in json.get("classes"):
		card_resource.classes.append(CardHelper.Class[class_string.replace(" ", "_")])
	for types_string in json.get("types"):
		card_resource.types.append(CardHelper.Type[types_string.replace(" ", "_").replace("-", "_")])
	for subtype_string in json.get("subtypes"):
		var formatted_subtype_string : String = subtype_string.replace(" ", "_").replace("-","_")
		if subtype_string == "1H" or subtype_string == "2H":
			formatted_subtype_string = "_" + formatted_subtype_string
		card_resource.subtypes.append(CardHelper.SubType[formatted_subtype_string])
	if json.has("talents"):
		for talents_string in json.get("talents"):
			card_resource.talents.append(CardHelper.Talent[talents_string.replace(" ", "_").replace("-", "_")])
	if json.has("keywords"):
		for keyword_string in json.get("keywords"):
			var formatted_keyword_string: String = keyword_string.replace(" ", "_").replace("-","_")
			card_resource.keywords.append(CardHelper.Keyword[formatted_keyword_string])
	if json.has("rarities"):
		for rarity_string in json.get("rarities"):
			var formatted_rarity_string: String = rarity_string.replace(" ", "_").replace("-","_")
			card_resource.rarities.append(CardHelper.Rarity[formatted_rarity_string])
	if json.has("rarity"):
		card_resource.rarity = CardHelper.Rarity[json.get("rarity").replace(" ", "_")]
	if json.has("functionalText"):
		card_resource.card_effect = json.get("functionalText")
	if json.has("cost"):
		card_resource.cost = json.get("cost")
	if json.has("pitch"):
		card_resource.pitch = json.get("pitch")
	if json.has("defense"):
		card_resource.defense = json.get("defense")
	if json.has("power"):
		card_resource.power = json.get("power")
	if json.has("intellect"):
		card_resource.intellect = json.get("intellect")
	if json.has("life"):
		card_resource.life = json.get("life")
	if json.has("image") and json.get("image").has("large"):
		card_resource.image_url = json.get("image").get("large")
	if json.has("artists"):
		card_resource.artist_name = json.get("artists")[0]
	if json.has("flipImage") and json.get("flipImage").has("large"):
		card_resource.flip_image_url = json.get("flipImage").get("large")
	if json.has("isExpansionSlot"):
		card_resource.is_expansion_slot = json.get("isExpansionSlot")
	for hero_string in json.get("legalHeroes"):
		var trimmed_hero_string : String = hero_string.replace(" ", "_").replace("'", "_")
		card_resource.legal_heroes.append(CardHelper.Hero[trimmed_hero_string])
