@tool
extends EditorScript

# Run this script in Godot Editor via Script -> Run
# It will export all pack data to Resources/Json/sets.json

const PACK_FILE_LOCATION : String = "res://PackResources/"

func _run():
	var packs_data : Array[Dictionary] = []
	
	# Pack enum mappings from PackOpenHelper.Sets
	var pack_enums : Dictionary = {
		"WelcomeToRathe": 0,
		"ArcaneRising": 1,
		"CrucibleOfWar": 2,
		"Monarch": 3,
		"TalesOfAria": 4,
		"Everfest": 5,
		"HistoryPackOne": 6,
		"Uprising": 7,
		"Dynasty": 8,
		"HistoryPackTwo": 9,
		"Outsiders": 10,
		"DuskTillDawn": 11,
		"BrightLights": 12,
		"HeavyHitters": 13,
		"PartTheMistveil": 14,
		"Rosetta": 15,
		"GemPack1": 16,
		"TheHunted": 17,
		"GemPack2": 18,
		"TreasurePack": 19,
		"HighSeas": 20,
		"MasteryPackGuardian": 21,
		"GemPack3": 22,
		"SuperSlam": 23,
		"CompendiumOfRathe": 24,
		"AntiquityPack": 25
	}
	
	# Set code mappings based on card.json set_ids
	var set_codes : Dictionary = {
		"WelcomeToRathe": "WTR",
		"ArcaneRising": "ARC",
		"CrucibleOfWar": "CRU",
		"Monarch": "MON",
		"TalesOfAria": "ELE",
		"Everfest": "EVR",
		"HistoryPackOne": "1HP",
		"Uprising": "UPR",
		"Dynasty": "DYN",
		"HistoryPackTwo": "2HP",
		"Outsiders": "OUT",
		"DuskTillDawn": "DTD",
		"BrightLights": "EVO",
		"HeavyHitters": "HVY",
		"PartTheMistveil": "MST",
		"Rosetta": "ROS",
		"GemPack1": "GEM",
		"TheHunted": "HNT",
		"GemPack2": "GEM",
		"TreasurePack": "SEA",
		"HighSeas": "SEA",
		"MasteryPackGuardian": "MPG",
		"GemPack3": "GEM",
		"SuperSlam": "SUP",
		"CompendiumOfRathe": "PEN",
		"AntiquityPack": "ANQ"
	}
	
	var pack_resources_dir : DirAccess = DirAccess.open(PACK_FILE_LOCATION)
	if pack_resources_dir == null:
		print("ERROR: Cannot open PackResources directory")
		return
	
	for file_name : String in pack_resources_dir.get_files():
		if !file_name.ends_with(".tres") and !file_name.ends_with(".res"):
			continue
		# Skip .depren files and only process one format per pack
		if file_name.ends_with(".depren"):
			continue
		# Prefer .tres over .res if both exist
		var base_name = file_name.replace(".tres", "").replace(".res", "")
		if file_name.ends_with(".res") and pack_resources_dir.file_exists(base_name + ".tres"):
			continue
			
		var pack_resource : PackResource = ResourceLoader.load(PACK_FILE_LOCATION + file_name)
		if pack_resource == null:
			print("WARNING: Can't load pack resource for " + file_name)
			continue
		
		var pack_name : String = base_name
		var pack_data : Dictionary = {
			"name": pack_name,
			"set_code": set_codes.get(pack_name, "UNKNOWN"),
			"pack_enum": pack_enums.get(pack_name, -1),
			"number_of_cards": pack_resource.number_of_cards,
			"pack_size": pack_resource.pack_size,
			
			"pull_rates": {
				"foil_rare_rarity": pack_resource.foil_rare_rarity,
				"super_rare_rarity": pack_resource.super_rare_rarity,
				"foil_super_rare_rarity": pack_resource.foil_super_rare_rarity,
				"majestic_rarity": pack_resource.majestic_rarity,
				"foil_majestic_rarity": pack_resource.foil_majestic_rarity,
				"legendary_rarity": pack_resource.legendary_rarity,
				"marvel_rarity": pack_resource.marvel_rarity,
				"fabled_rarity": pack_resource.fabled_rarity,
				"expansion_slot_rarity": pack_resource.expansion_slot_rarity
			},
			
			"pack_contents": {
				"generics_commons_per_pack": pack_resource.generics_commons_per_pack,
				"tokens_per_pack": pack_resource.tokens_per_pack,
				"class_commons_per_pack": pack_resource.class_commons_per_pack,
				"guaranteed_rares_per_pack": pack_resource.guaranteed_rares_per_pack,
				"juicer_rares_per_pack": pack_resource.juicer_rares_per_pack,
				"equipment_per_pack": pack_resource.equipment_per_pack,
				"non_token_premium_foil_per_pack": pack_resource.non_token_premium_foil_per_pack,
				"expansion_slot_cards_per_pack": pack_resource.expansion_slot_cards_per_pack
			}
		}
		
		packs_data.append(pack_data)
		print("Exported: " + pack_name)
	
	# Sort by pack_enum for consistent ordering
	packs_data.sort_custom(func(a, b): return a.pack_enum < b.pack_enum)
	
	# Write to JSON file
	var json_string = JSON.stringify(packs_data, "\t")
	var file = FileAccess.open("res://Resources/Json/sets.json", FileAccess.WRITE)
	if file:
		file.store_string(json_string)
		file.close()
		print("\n=== SUCCESS ===")
		print("Exported " + str(packs_data.size()) + " packs to res://Resources/Json/sets.json")
	else:
		print("ERROR: Could not write to sets.json")
