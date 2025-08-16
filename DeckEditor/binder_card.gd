extends Panel

class_name BinderCard

signal card_hovered
signal card_unhovered
signal card_add_to_main
signal card_add_to_inventory
signal card_add_to_maybe
signal card_add_to_banlist
signal card_add_to_binder

@onready var name_label: Label = $HBoxContainer/CardTexture/NameLabel
@onready var type_label: Label = $HBoxContainer/VBoxContainer/TypeLabel
@onready var class_label: Label = $HBoxContainer/VBoxContainer/ClassLabel
@onready var effect_label: RichTextLabel = $HBoxContainer/CardTexture/EffectLabel
@onready var pitch_label: Label = $HBoxContainer/VBoxContainer2/PitchLabel
@onready var attack_label: Label = $HBoxContainer/VBoxContainer2/AttackLabel
@onready var defense_label: Label = $HBoxContainer/VBoxContainer2/DefenseLabel
@onready var talents_label: Label = $HBoxContainer/VBoxContainer/TalentsLabel
@onready var cost_label: Label = $HBoxContainer/VBoxContainer2/CostLabel
@onready var life_label: Label = $HBoxContainer/VBoxContainer/LifeLabel
@onready var intellect_label: Label = $HBoxContainer/VBoxContainer2/IntellectLabel

@onready var card_texture: TextureRect = $HBoxContainer/CardTexture
@onready var quantity_label: Label = $HBoxContainer/CardTexture/QuantityLabel
@onready var card_menu_panel: Panel = $CardMenuPanel

@onready var main_button: Button = $CardMenuPanel/VBoxContainer/Main
@onready var inventory_button: Button = $CardMenuPanel/VBoxContainer/Inventory
@onready var maybe_button: Button = $CardMenuPanel/VBoxContainer/Maybe
@onready var banlist_button: Button = $CardMenuPanel/VBoxContainer/Banlist
@onready var binder_button: Button = $CardMenuPanel/VBoxContainer/Binder
@onready var banned_rect: TextureRect = $BannedRect


@onready var v_box_container: VBoxContainer = $HBoxContainer/VBoxContainer
@onready var v_box_container_2: VBoxContainer = $HBoxContainer/VBoxContainer2

@export var is_banlist_card : bool = false
@export var is_binder_card : bool = false
const FAB_CARD_BACK = preload("res://Resources/Images/fab_card_back.webp")
var is_banned : bool = false
var card_resource : CardResource
var quantity : int = 0
func _ready() -> void:
	if card_resource != null:
		update_labels()
		if is_banlist_card:
			banlist_button.show()
			binder_button.hide()
			main_button.hide()
			inventory_button.hide()
			maybe_button.hide()
			banlist_button.pressed.connect(func(): card_add_to_banlist.emit(card_resource))
		elif is_binder_card:
			binder_button.show()
			banlist_button.hide()
			main_button.hide()
			inventory_button.hide()
			maybe_button.hide()
			binder_button.pressed.connect(func(): card_add_to_binder.emit([1,card_resource]))
		else:
			main_button.pressed.connect(func(): card_add_to_main.emit([1,card_resource]))
			inventory_button.pressed.connect(func(): card_add_to_inventory.emit([1,card_resource]))
			maybe_button.pressed.connect(func(): card_add_to_maybe.emit([1,card_resource]))

	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func _on_mouse_entered():
	card_menu_panel.show()
	card_hovered.emit(card_resource)

func _on_mouse_exited():
	card_menu_panel.hide()
	card_unhovered.emit(card_resource)
			
func update_labels() -> void:
	var visible_left_column_item_count : int = 4
	var visible_right_column_item_count : int = 0
	
	name_label.text = card_resource.name
	if name_label.text == "":
		visible_left_column_item_count -= 1
		name_label.hide()
	type_label.text = card_resource.pretty_print_types()
	if type_label.text == "":
		visible_left_column_item_count -= 1
		type_label.hide()
	class_label.text = card_resource.pretty_print_classes()
	if class_label.text == "":
		visible_left_column_item_count -= 1
		class_label.hide()
	talents_label.text = card_resource.pretty_print_talents()
	if talents_label.text == "":
		visible_left_column_item_count -= 1
		talents_label.hide()

	if card_resource.card_effect:
		effect_label.text = card_resource.pretty_print_effect_text()
	if card_resource.pitch:
		visible_right_column_item_count += 1
		pitch_label.text = "Pitch: " + str(card_resource.pitch)
	else:
		pitch_label.hide()
	if card_resource.power:
		visible_right_column_item_count += 1
		attack_label.text = "Power: " + str(card_resource.power)
	else:
		attack_label.hide()
	if card_resource.defense:
		visible_right_column_item_count += 1
		defense_label.text = "Defense: " + str(card_resource.defense)
	else:
		defense_label.hide()
	if card_resource.cost:
		visible_right_column_item_count += 1
		cost_label.text = "Cost: " + str(card_resource.cost)
	else:
		cost_label.hide()
		
	if card_resource.life != 0:
		life_label.text = "Life: " + str(card_resource.life)
		life_label.show()
		visible_right_column_item_count += 1
	else:
		life_label.hide()
	
	if card_resource.intellect != 0:
		intellect_label.text = "Int: " + str(card_resource.intellect)
		intellect_label.show()
	else:
		intellect_label.hide()
	if visible_left_column_item_count <= 3 and visible_right_column_item_count <= 3:
		effect_label.position.y -= name_label.size.y - 3
		effect_label.size.y += name_label.size.y - 3
		if visible_left_column_item_count <= 2 and visible_right_column_item_count <= 2:
			effect_label.position.y -= name_label.size.y - 3
			effect_label.size.y += name_label.size.y - 3
	quantity_label.text = "x" + str(quantity)
	card_menu_panel.hide()

func should_load_texture(scroll_container_rect:Rect2) -> void:
	if card_texture.get_global_rect().intersects(scroll_container_rect) and visible:
		card_texture.texture = card_resource.load_texture()
	else:
		card_texture.texture = FAB_CARD_BACK

func ban_card() -> void:
	banned_rect.show()
	is_banned = true

func unban_card() -> void:
	banned_rect.hide()
	is_banned = false

func check_if_banned(banlist : BanlistResource) -> void:
	if banlist != null:
		if card_resource.id in banlist.cards.keys():
			ban_card()
		else:
			unban_card()
	else:
		unban_card()
