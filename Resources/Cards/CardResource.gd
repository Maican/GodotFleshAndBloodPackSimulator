extends Resource

class_name CardResource

@export var id : String = ""
@export var name : String = "Cracked Bauble"
@export var classes : Array[CardHelper.Class] = []
@export var types : Array[CardHelper.Type] = []
@export var subtypes : Array[CardHelper.SubType] = []
@export var rarity : CardHelper.Rarity = CardHelper.Rarity.Basic
@export var talents : Array[CardHelper.Talent] = []
@export var keywords : Array[CardHelper.Keyword] = []
@export var card_effect : String = ""
@export var cost : int
@export var pitch : int
@export var defense : int
@export var power : int
@export var intellect : int
@export var life : int
@export var flavour_text : String = ""
@export var image_url : String
@export var artist_name = ""
@export var legal_heroes : Array[CardHelper.Hero] = []
@export var image_path : String = ""
@export var small_image_path : String = ""
@export var print_id : String = ""
@export var unique_set_print_ids : Dictionary[int, String] = {}
@export var flip_image_url : String = ""
@export var flip_image_path : String = ""
@export var is_expansion_slot : bool = false
@export var rarities : Array[CardHelper.Rarity] = []

func load_texture() -> CompressedTexture2D:
	return ResourceLoader.load(image_path, ".webp")
	
func load_flip_texture() -> CompressedTexture2D:
	return ResourceLoader.load(flip_image_path, ".webp")

func pretty_print_classes() -> String:
	var pretty_string : String = ""
	for card_class : CardHelper.Class in classes:
		pretty_string += CardHelper.Class.keys()[card_class].replace("_", " ") + ", "
	
	pretty_string = pretty_string.trim_suffix(", ")
	return pretty_string

func pretty_print_types() -> String:
	var pretty_string : String = ""
	for card_type : CardHelper.Type in types:
		pretty_string += CardHelper.Type.keys()[card_type].replace("_", " ") + ", "
	
	pretty_string = pretty_string.trim_suffix(", ")
	return pretty_string

func pretty_print_subtypes() -> String:
	var pretty_string : String = ""
	for card_subtype : CardHelper.SubType in subtypes:
		pretty_string += CardHelper.SubType.keys()[card_subtype].replace("_", " ") + ", "
	
	pretty_string = pretty_string.trim_suffix(", ")
	return pretty_string

func pretty_print_talents() -> String:
	var pretty_string : String = ""
	for card_talent : CardHelper.Talent in talents:
		pretty_string += CardHelper.Talent.keys()[card_talent].replace("_", " ") + ", "
	
	pretty_string = pretty_string.trim_suffix(", ")
	return pretty_string

func pretty_print_keywords() -> String:
	var pretty_string : String = ""
	for card_keyword : CardHelper.Keyword in keywords:
		pretty_string += CardHelper.Keyword.keys()[card_keyword].replace("_", " ") + ", "
	
	pretty_string = pretty_string.trim_suffix(", ")
	return pretty_string
	
func pretty_print_effect_text() -> String:
	var card_effect_text : String = card_effect.replace("\n\n", "\n")
	card_effect_text = card_effect_text.replace("{p}", "[img width='10' height='10']" + CardHelper.ICON_PWR + "[/img]")
	card_effect_text = card_effect_text.replace("{d}", "[img width='10' height='10']" + CardHelper.ICON_DEF + "[/img]")
	card_effect_text = card_effect_text.replace("{h}", "[img width='10' height='10']" + CardHelper.ICON_HP + "[/img]")
	card_effect_text = card_effect_text.replace("{i}", "[img width='10' height='10']" + CardHelper.ICON_INT + "[/img]")
	card_effect_text = card_effect_text.replace("{r}", "[img width='10' height='10']" + CardHelper.ICON_COST + "[/img]")
	var split_card_effect_text : Array = card_effect_text.split("**")
	var return_text : String = ""
	for i : int in split_card_effect_text.size():
		if i % 2 == 1:
			split_card_effect_text[i] = "[b][i]" + split_card_effect_text[i] + "[/i][/b]"
		return_text += split_card_effect_text[i]
	return return_text
