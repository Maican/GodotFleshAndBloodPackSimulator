@tool
extends Resource

class_name PackResource

@export var pack_enum : PackOpenHelper.Sets = PackOpenHelper.Sets.WelcomeToRathe
@export var number_of_cards : int = 246
@export var pack_size : int = 16

func clear_cards():
	rare_cards = []
	super_rare_cards = []
	majestic_cards = []
	shortprint_majestic_cards = []
	legendary_cards = []
	fabled_cards = []
	token_cards = []
	equipment_cards = []
	generic_common_cards = []
	class_common_cards = []
	expansion_slot_cards = []
	marvel_cards = []
	promo_cards = []
	ResourceSaver.save(self, self.resource_path)
	
@export_tool_button("clear_cards") var clear_cards_action = clear_cards

@export_group("Pullrates")
@export var foil_rare_rarity : float = 5
@export var super_rare_rarity : float = 6
@export var foil_super_rare_rarity : float = 9
@export var majestic_rarity : float = 12
@export var foil_majestic_rarity : float = 18
@export var legendary_rarity : float = 96
@export var marvel_rarity : float = 100
@export var fabled_rarity : float = 960
@export var expansion_slot_rarity : float = 15.0
@export_group("Pack contents")
@export var generics_commons_per_pack : int = 4
@export var tokens_per_pack : int = 1
@export var class_commons_per_pack : int = 7
@export var guaranteed_rares_per_pack : int = 1
@export var juicer_rares_per_pack : int = 1
@export var equipment_per_pack : int = 1
@export var non_token_premium_foil_per_pack : int = 1
@export var expansion_slot_cards_per_pack : int = 0

@export_group("Cards")
@export var rare_cards : Array[CardResource] = []
@export var super_rare_cards : Array[CardResource] = []
@export var majestic_cards : Array[CardResource] = []
@export var shortprint_majestic_cards : Array[CardResource] = []
@export var legendary_cards : Array[CardResource] = []
@export var fabled_cards : Array[CardResource] = []
@export var token_cards : Array[CardResource] = []
@export var equipment_cards : Array[CardResource] = []
@export var generic_common_cards : Array[CardResource] = []
@export var class_common_cards : Array[CardResource] = []
@export var expansion_slot_cards : Array[CardResource] = []
@export var marvel_cards : Array[CardResource] = []
@export var promo_cards : Array[CardResource] = []

#premium foil is any non-token card apparently.
#WELCOME TO RATHE
#Fabled CF	~960 packs	~0.025 pulls	~30–40 boxes
#Legendary	~96 packs	~0.25 pulls	~4 boxes
#Majestic	~12 packs	~2 pulls	~0.5 boxes
#Super Rare	~6 packs	~4 pulls	~0.25 boxes
#Rare	~27.5 packs	~0.87 pulls (~21 per box)	~1.13 boxes
#Common	~11 packs	~2.18 pulls (~52 per box)	~0.46 boxes
