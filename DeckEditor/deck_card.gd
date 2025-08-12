extends Panel

class_name DeckCard

@onready var remove_button: Button = $CardMenuPanel/VBoxContainer/RemoveButton
@onready var inventory_button: Button = $CardMenuPanel/VBoxContainer/InventoryButton
@onready var maybe_button: Button = $CardMenuPanel/VBoxContainer/MaybeButton
@onready var main_button: Button = $CardMenuPanel/VBoxContainer/MainButton
@onready var card_menu_panel: Panel = $CardMenuPanel
@onready var v_box_container: VBoxContainer = $VBoxContainer

signal card_hovered
signal card_unhovered
signal card_remove
signal card_move_to_main
signal card_move_to_inventory
signal card_move_to_maybe

var card_location : DeckHelper.CardLocation = DeckHelper.CardLocation.MAIN
var card_resource : CardResource
var quantity : int = 1

func _ready() -> void:
	mouse_entered.connect(_on_mouse_entered.bind(card_resource))
	mouse_exited.connect(_on_mouse_exited.bind(card_resource))
	match card_location:
		DeckHelper.CardLocation.HERO_EQUIP:
			main_button.hide()
		DeckHelper.CardLocation.MAIN:
			main_button.hide()
		DeckHelper.CardLocation.INVENTORY:
			inventory_button.hide()
		DeckHelper.CardLocation.MAYBE:
			maybe_button.hide()

	remove_button.pressed.connect(func(): card_remove.emit(self))
	inventory_button.pressed.connect(func(): card_move_to_inventory.emit(self))
	maybe_button.pressed.connect(func(): card_move_to_maybe.emit(self))
	main_button.pressed.connect(func(): card_move_to_main.emit(self))
	update_display()
	custom_minimum_size = v_box_container.get_rect().size

func _on_mouse_entered(new_card_resource : CardResource):
	card_menu_panel.show()
	card_hovered.emit(new_card_resource)

func _on_mouse_exited(new_card_resource : CardResource):
	card_menu_panel.hide()
	card_unhovered.emit(new_card_resource)

func update_display():
	if v_box_container == null:
		return
	var child_count : int = 0
	for child in v_box_container.get_children():
		if child_count > quantity - 1:
			v_box_container.get_child(child_count).hide()
		else:
			var child_rect : TextureRect = v_box_container.get_child(child_count)
			child_rect.texture = card_resource.load_texture()
			child_rect.show()
		child_count += 1
		
	await get_tree().create_timer(0.001).timeout
	custom_minimum_size = v_box_container.get_rect().size

func set_card_quantity(new_quantity : int):
	quantity = new_quantity
	update_display()
