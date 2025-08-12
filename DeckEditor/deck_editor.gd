extends Panel

class_name DeckEditor

@onready var hero_arena_container: HBoxContainer = $ScrollContainer/VBoxContainer/HeroArenaContainer
@onready var main_deck_grid_container: GridContainer = $ScrollContainer/VBoxContainer/MainDeckGridContainer
@onready var inventory_grid_container: GridContainer = $ScrollContainer/VBoxContainer/InventoryGridContainer
@onready var maybe_grid_container: GridContainer = $ScrollContainer/VBoxContainer/MaybeGridContainer
@onready var binder_cards : BinderCards = $BinderCards
@onready var binder_list: OptionButton = $BinderList
@onready var hover_panel: CardHoverPanel = $HoverPanel

@onready var hero_arena_label: Label = $ScrollContainer/VBoxContainer/HeroArenaLabel
@onready var deck_label: Label = $ScrollContainer/VBoxContainer/DeckLabel
@onready var inventory_label: Label = $ScrollContainer/VBoxContainer/InventoryLabel


@onready var load_deck_button: Button = $HBoxContainer/LoadDeckButton
@onready var deck_type_options: OptionButton = $HBoxContainer/DeckTypeOptions
@onready var add_deck_button: Button = $HBoxContainer/AddDeckButton
@onready var deck_list_options: OptionButton = $HBoxContainer/DeckListOptions
@onready var save_deck_button: Button = $HBoxContainer/SaveDeckButton
@onready var save_deck_as_button: Button = $HBoxContainer/SaveDeckAsButton
@onready var export_deck_button: Button = $HBoxContainer/ExportDeckButton

const DECK_CARD = preload("res://DeckEditor/deck_card.tscn")

var hero_and_equipment_cards : Dictionary[String, Array] = {}
var inventory_cards : Dictionary[String, Array] = {}
var maybe_cards : Dictionary[String, Array] = {}
var main_cards : Dictionary[String, Array] = {}

var current_deck : DeckResource

func _ready() -> void:
	fill_binder_list()
	fill_deck_list()
	binder_list.item_selected.connect(binder_cards.binder_selected.bind(binder_list))

	add_deck_button.pressed.connect(add_new_deck)
	save_deck_button.pressed.connect(save_cards_to_deck)
	save_deck_as_button.pressed.connect(add_new_deck.bind(true))
	load_deck_button.pressed.connect(load_cards_from_deck)
	export_deck_button.pressed.connect(export_deck)
	binder_cards.add_card_to_main.connect(add_card_to_main)
	binder_cards.add_card_to_inventory.connect(add_card_to_inventory)
	binder_cards.add_card_to_maybe.connect(add_card_to_maybe)
	binder_cards.show_hover_panel.connect(show_hover_panel)
	binder_cards.hide_hover_panel.connect(hide_hover_panel)
	load_deck_button.disabled = true
	save_deck_button.disabled = true
	export_deck_button.disabled = true
	deck_list_options.item_selected.connect(func(selected_idx):
		if selected_idx != 0:
			load_deck_button.disabled = false
			save_deck_button.disabled = false
			export_deck_button.disabled = false
		else:
			load_deck_button.disabled = true
			save_deck_button.disabled = true
			export_deck_button.disabled = true
	)

func fill_binder_list() -> void:
	binder_list.clear()
	binder_list.add_item("")
	for new_binder_name : String in BinderHelper.binders.keys():
		var new_binder : BinderResource = BinderHelper.binders[new_binder_name]
		if new_binder != null and new_binder.resource_name != "":
			binder_list.add_item(new_binder.resource_name)

func show_hover_panel(card_resource : CardResource) -> void:
	hover_panel.show()
	hover_panel.set_card_resource(card_resource)

func hide_hover_panel(_card_resource : CardResource) -> void:
	hover_panel.hide()

func _on_main_menu_button_pressed() -> void:
	SceneChanger.switch_to_main_menu_scene()

func add_card_to_main(quantity_and_card_array: Array):
	var quantity : int = quantity_and_card_array[0]
	var card_resource : CardResource = quantity_and_card_array[1]
	var is_hero = CardHelper.Type.Hero in card_resource.types
	var is_equipment = CardHelper.Type.Equipment in card_resource.types
	var is_weapon = CardHelper.Type.Weapon in card_resource.types or CardHelper.SubType.Off_Hand in card_resource.subtypes
	var card_name = card_resource.name
	if !is_hero and !is_equipment and !is_weapon:
		if main_cards.has(card_name):
			if main_cards[card_name][0] + quantity > 3:
				print("Cannot add that many of this card.")
				return
			main_cards[card_name][0] += quantity
			var card_scene : DeckCard = main_deck_grid_container.get_node(card_name)
			if card_scene:
				card_scene.set_card_quantity(main_cards[card_name][0])
		else:
			main_cards[card_name] = [quantity, card_resource]
			var deck_card_scene : DeckCard = DECK_CARD.instantiate()
			deck_card_scene.name = card_name
			deck_card_scene.card_location = DeckHelper.CardLocation.MAIN
			deck_card_scene.card_resource = card_resource
			deck_card_scene.card_hovered.connect(show_hover_panel)
			deck_card_scene.card_unhovered.connect(hide_hover_panel)
			deck_card_scene.card_remove.connect(remove_card)
			deck_card_scene.card_move_to_inventory.connect(move_card_to_inventory)
			deck_card_scene.card_move_to_maybe.connect(move_card_to_maybe)
			deck_card_scene.card_move_to_main.connect(move_card_to_main)
			main_deck_grid_container.add_child(deck_card_scene)
			deck_card_scene.set_card_quantity(quantity)
	# Check for hero or equipment
	else:
		var can_equip : bool = can_equip_hero_or_equip(is_hero, is_equipment,is_weapon, card_resource)
		if can_equip:
			if hero_and_equipment_cards.has(card_resource.name):
				hero_and_equipment_cards[card_resource.name][0] += quantity
			else:
				hero_and_equipment_cards[card_resource.name] = [quantity, card_resource]
			var deck_card_scene : DeckCard = DECK_CARD.instantiate()
			deck_card_scene.card_location = DeckHelper.CardLocation.HERO_EQUIP
			deck_card_scene.card_resource = card_resource
			deck_card_scene.card_hovered.connect(show_hover_panel)
			deck_card_scene.card_unhovered.connect(hide_hover_panel)
			deck_card_scene.card_remove.connect(remove_card)
			deck_card_scene.card_move_to_inventory.connect(move_card_to_inventory)
			deck_card_scene.card_move_to_maybe.connect(move_card_to_maybe)
			deck_card_scene.card_move_to_main.connect(move_card_to_main)
			hero_arena_container.add_child(deck_card_scene)
	populate_card_totals()

func add_card_to_inventory(quantity_and_card_array: Array):
	var quantity : int = quantity_and_card_array[0]
	var card_resource : CardResource = quantity_and_card_array[1]
	var types = card_resource.types
	var is_hero = card_resource.types.has(CardHelper.Type.Hero)
	var is_equipment = CardHelper.Type.Equipment in card_resource.types
	var is_weapon = CardHelper.Type.Weapon in card_resource.types
	if is_hero:
		return
		
	var card_name = card_resource.name
	if inventory_cards.has(card_name):
		if inventory_cards[card_name][0] + quantity > 3:
			print("Cannot add that many of this card.")
			return
		inventory_cards[card_name][0] += quantity
		var card_scene : DeckCard = inventory_grid_container.get_node(card_name)
		if card_scene:
			card_scene.set_card_quantity(inventory_cards[card_name][0])
	else:
		inventory_cards[card_name] = [quantity, card_resource]
		var deck_card_scene : DeckCard = DECK_CARD.instantiate()
		deck_card_scene.name = card_name
		deck_card_scene.card_location = DeckHelper.CardLocation.INVENTORY
		deck_card_scene.card_resource = card_resource
		deck_card_scene.card_hovered.connect(show_hover_panel)
		deck_card_scene.card_unhovered.connect(hide_hover_panel)
		deck_card_scene.card_remove.connect(remove_card)
		deck_card_scene.card_move_to_inventory.connect(move_card_to_inventory)
		deck_card_scene.card_move_to_maybe.connect(move_card_to_maybe)
		deck_card_scene.card_move_to_main.connect(move_card_to_main)
		inventory_grid_container.add_child(deck_card_scene)
		deck_card_scene.set_card_quantity(quantity)
	populate_card_totals()

func add_card_to_maybe(quantity_and_card_array: Array):
	var quantity : int = quantity_and_card_array[0]
	var card_resource : CardResource = quantity_and_card_array[1]
	var types = card_resource.types
	var is_hero = card_resource.types.has(CardHelper.Type.Hero)
	var is_equipment = CardHelper.Type.Equipment in card_resource.types
	var is_weapon = CardHelper.Type.Weapon in card_resource.types
	if is_hero:
		return
		
	var card_name = card_resource.name
	if maybe_cards.has(card_name):
		if maybe_cards[card_name][0] + quantity > 3:
			print("Cannot add that many of this card.")
			return
		maybe_cards[card_name][0] += quantity
		var card_scene : DeckCard = maybe_grid_container.get_node(card_name)
		if card_scene:
			card_scene.set_card_quantity(maybe_cards[card_name][0])
	else:
		maybe_cards[card_name] = [quantity, card_resource]
		var deck_card_scene : DeckCard = DECK_CARD.instantiate()
		deck_card_scene.name = card_name
		deck_card_scene.card_location = DeckHelper.CardLocation.MAYBE
		deck_card_scene.card_resource = card_resource
		deck_card_scene.card_hovered.connect(show_hover_panel)
		deck_card_scene.card_unhovered.connect(hide_hover_panel)
		deck_card_scene.card_remove.connect(remove_card)
		deck_card_scene.card_move_to_inventory.connect(move_card_to_inventory)
		deck_card_scene.card_move_to_maybe.connect(move_card_to_maybe)
		deck_card_scene.card_move_to_main.connect(move_card_to_main)
		maybe_grid_container.add_child(deck_card_scene)
		deck_card_scene.set_card_quantity(quantity)
	populate_card_totals()

func fill_deck_list() -> void:
	deck_list_options.clear()
	deck_list_options.add_item("")
	for deck_index : int in DeckHelper.decks.size():
		var deck_name : String = DeckHelper.decks.keys()[deck_index]
		var deck_resource : DeckResource = DeckHelper.decks[deck_name]
		if deck_resource != null and deck_name != "":
			deck_list_options.add_item(deck_name, deck_index + 1)

func add_new_deck(and_save_deck : bool = false) -> void:
	var popup = Popup.new()
	popup.title = "Create Deck"
	popup.min_size = Vector2(300, 100)

	var vbox = VBoxContainer.new()
	vbox.position = Vector2(20,0)
	vbox.custom_minimum_size = Vector2(250, 90)
	var label = Label.new()
	label.text = "Deck Name:"
	var name_edit = LineEdit.new()
	name_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(label)
	vbox.add_child(name_edit)

	var confirm = Button.new()
	confirm.text = "Create"
	confirm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(confirm)

	popup.add_child(vbox)
	add_child(popup)
	popup.popup_centered()

	confirm.pressed.connect(func():
		var deck_name = name_edit.text.strip_edges()
		if deck_name != "":
			var deck = DeckResource.new()
			var dir : DirAccess = DirAccess.open("user://")
			deck.resource_name = deck_name
			deck.name = deck_name
			var resource_path = "user://DeckResources/" + deck_name + ".res"
			if !dir.file_exists(resource_path):
				ResourceSaver.save(deck, resource_path)
			DeckHelper.decks[deck_name] = deck
			var saved_deck_index : int = DeckHelper.decks.keys().find(deck_name)
			fill_deck_list()
			deck_list_options.select(saved_deck_index + 1)
			if and_save_deck and deck_list_options.selected != 0:
				save_cards_to_deck()
			deck_list_options.item_selected.emit(deck_list_options.selected)
		popup.queue_free())
	
func save_cards_to_deck() -> void:
	var selected_idx = deck_list_options.selected
	if selected_idx == -1:
		var dialog = AcceptDialog.new()
		dialog.dialog_text = "No deck selected to save cards to."
		dialog.title = "Warning"
		add_child(dialog)
		dialog.popup_centered()
		await dialog.confirmed
		return
	var deck_name : String = deck_list_options.get_item_text(selected_idx)
	var deck_path : String = "user://DeckResources/" + deck_name + ".res"
	var deck : DeckResource = ResourceLoader.load(deck_path)
	if deck == null:
		print("Deck resource not found: " + deck_path)
		return
	deck.clear_deck()
	for card_name : String in hero_and_equipment_cards:
		var card_resource : CardResource = hero_and_equipment_cards[card_name][1]
		if card_resource.types.has(CardHelper.Type.Hero):
			deck.hero = card_resource
		else:
			deck.main_equipment.set(card_name, hero_and_equipment_cards[card_name])
	for card_name : String in main_cards:
		deck.main_deck.set(card_name, main_cards[card_name])
	for card_name : String in inventory_cards:
		deck.inventory.set(card_name, inventory_cards[card_name])
	for card_name : String in maybe_cards:
		deck.maybes.set(card_name, maybe_cards[card_name])

	ResourceSaver.save(deck, deck.resource_path)

func load_cards_from_deck() -> void:
	var selected_idx = deck_list_options.get_selected_id()
	if selected_idx == 0:
		var dialog = AcceptDialog.new()
		dialog.dialog_text = "No deck selected to load from."
		dialog.title = "Warning"
		add_child(dialog)
		dialog.popup_centered()
		await dialog.confirmed
		return
	var deck_name : String = deck_list_options.get_item_text(selected_idx)
	var deck_path : String = "user://DeckResources/" + deck_name + ".res"
	var deck : DeckResource = ResourceLoader.load(deck_path)
	if deck == null:
		print("Deck resource not found: " + deck_path)
		return
	
	remove_all_cards()
	if deck.hero != null:
		add_card_to_main([1,deck.hero])
	for card_id : String in deck.main_equipment:
		add_card_to_main(deck.main_equipment[card_id])
	for card_id : String in deck.main_deck:
		add_card_to_main(deck.main_deck[card_id])
	for card_id : String in deck.inventory:
		add_card_to_inventory(deck.inventory[card_id])
	for card_id : String in deck.maybes:
		add_card_to_maybe(deck.maybes[card_id])

func remove_card(card_scene : DeckCard, quantity_to_remove : int = 1) -> void:
	var new_quantity: int = 0
	match card_scene.card_location:
		DeckHelper.CardLocation.HERO_EQUIP:
			if hero_and_equipment_cards.has(card_scene.card_resource.name):
				if hero_and_equipment_cards[card_scene.card_resource.name][0] > quantity_to_remove:
					hero_and_equipment_cards[card_scene.card_resource.name][0] -= quantity_to_remove
					new_quantity = hero_and_equipment_cards[card_scene.card_resource.name][0]
				else:
					hero_and_equipment_cards.erase(card_scene.card_resource.name)
		DeckHelper.CardLocation.MAIN:
			if main_cards.has(card_scene.card_resource.name):
				if main_cards[card_scene.card_resource.name][0] > quantity_to_remove:
					main_cards[card_scene.card_resource.name][0] -= quantity_to_remove
					new_quantity = main_cards[card_scene.card_resource.name][0]
				else:
					main_cards.erase(card_scene.card_resource.name)
		DeckHelper.CardLocation.INVENTORY:
			if inventory_cards.has(card_scene.card_resource.name):
				if inventory_cards[card_scene.card_resource.name][0] > quantity_to_remove:
					inventory_cards[card_scene.card_resource.name][0] -= quantity_to_remove
					new_quantity = inventory_cards[card_scene.card_resource.name][0]
				else:
					inventory_cards.erase(card_scene.card_resource.name)
		DeckHelper.CardLocation.MAYBE:
			if maybe_cards.has(card_scene.card_resource.name):
				if maybe_cards[card_scene.card_resource.name][0] > quantity_to_remove:
					maybe_cards[card_scene.card_resource.name][0] -= quantity_to_remove
					new_quantity = maybe_cards[card_scene.card_resource.name][0]
				else:
					maybe_cards.erase(card_scene.card_resource.name)
	card_scene.set_card_quantity(new_quantity)
	if new_quantity == 0:
		card_scene.queue_free()
	populate_card_totals()

func move_card_to_main(card_scene:DeckCard) -> void:
	var card_resource : CardResource = card_scene.card_resource
	add_card_to_main([1,card_resource])
	remove_card(card_scene)
	
func move_card_to_inventory(card_scene:DeckCard) -> void:
	var card_resource : CardResource = card_scene.card_resource
	add_card_to_inventory([1,card_resource])
	remove_card(card_scene)
	
func move_card_to_maybe(card_scene:DeckCard) -> void:
	var card_resource : CardResource = card_scene.card_resource
	add_card_to_maybe([1,card_resource])
	remove_card(card_scene)

func remove_all_cards() -> void:
	for card_scene :DeckCard in hero_arena_container.get_children():
		remove_card(card_scene,3)
	for card_scene :DeckCard in main_deck_grid_container.get_children():
		remove_card(card_scene,3)
	for card_scene :DeckCard in inventory_grid_container.get_children():
		remove_card(card_scene,3)
	for card_scene :DeckCard in maybe_grid_container.get_children():
		remove_card(card_scene,3)

func export_deck() -> void:
	var selected_idx = deck_list_options.get_selected_id()
	if selected_idx == -1:
		var dialog = AcceptDialog.new()
		dialog.dialog_text = "No deck selected to export"
		dialog.title = "Warning"
		add_child(dialog)
		dialog.popup_centered()
		await dialog.confirmed
		return
	var deck_name : String = deck_list_options.get_item_text(selected_idx)
	var deck_path : String = "user://DeckResources/" + deck_name + ".res"
	var deck : DeckResource = ResourceLoader.load(deck_path)
	if deck == null:
		print("Deck resource not found: " + deck_path)
		return
	if deck.hero == null:
		var dialog = AcceptDialog.new()
		dialog.dialog_text = "No hero selected to export deck. (Did you forget to save first?)"
		dialog.title = "Warning"
		add_child(dialog)
		dialog.popup_centered()
		await dialog.confirmed
		return

	var deck_string = ""
	deck_string += "Name: " + deck.name + "\n"
	deck_string += "Format:\t" + DeckHelper.get_pretty_deck_type(deck.deck_type) + "\n"
	deck_string += "Hero / Class:\t" + deck.hero.name + "\n"
	deck_string += "\n"
	deck_string += "Arena cards\n"
	for card_name : String in deck.main_equipment:
		deck_string += str(deck.main_equipment[card_name][0]) + "x " + card_name + "\n"
	var inventory_non_equipment_cards : Dictionary[String, Array] = {}
	for card_name : String in deck.inventory:
		var card_resource : CardResource = deck.inventory[card_name][1]
		if card_resource.types.find(CardHelper.Type.Equipment):
			deck_string += str(deck.inventory[card_name][0]) + "x " + card_name + "\n"
		else:
			inventory_non_equipment_cards.set(card_name, deck.inventory[card_name])
	deck_string += "\n"
	deck_string += "Deck cards\n"
	for card_name : String in deck.main_deck:
		deck_string += str(deck.main_deck[card_name][0]) + "x " + card_name + "\n"
	for card_name : String in inventory_non_equipment_cards:
		deck_string += str(inventory_non_equipment_cards[card_name][0]) + "x " + card_name + "\n"
	DisplayServer.clipboard_set(deck_string)
	var dialog = AcceptDialog.new()
	dialog.dialog_text = "Saved deck set to clipboard."
	dialog.title = "Success"
	add_child(dialog)
	dialog.popup_centered()
	await dialog.confirmed
	return

func can_equip_hero_or_equip(is_hero : bool, is_equipment : bool, is_weapon : bool, card_resource : CardResource) -> bool:
	if is_equipment and !is_weapon:
		for equip_quantity_and_card_resource : Array in hero_and_equipment_cards.values():
			var equip_card_resource : CardResource = equip_quantity_and_card_resource[1]
			for subtype : CardHelper.SubType in card_resource.subtypes:
				match subtype:
					CardHelper.SubType.Arms,CardHelper.SubType.Legs,CardHelper.SubType.Chest,CardHelper.SubType.Head:
						if subtype in equip_card_resource.subtypes:
							return false
	elif is_weapon:
		var is_one_handed = CardHelper.SubType._1H in card_resource.subtypes
		var is_off_hand = CardHelper.SubType.Off_Hand in card_resource.subtypes
		if !is_one_handed and !is_off_hand:
			for equip_quantity_and_card_resource : Array in hero_and_equipment_cards.values():
				var equip_card_resource : CardResource = equip_quantity_and_card_resource[1]
				if CardHelper.Type.Weapon in equip_card_resource.types or CardHelper.SubType.Off_Hand in equip_card_resource.subtypes:
					return false
		elif is_one_handed:
			var hands_full : int = 0
			for equip_quantity_and_card_resource : Array in hero_and_equipment_cards.values():
				var equip_card_resource : CardResource = equip_quantity_and_card_resource[1]
				if CardHelper.SubType._1H in equip_card_resource.subtypes or CardHelper.SubType.Off_Hand in equip_card_resource.subtypes:
					hands_full += 1
					if hands_full > 1:
						return false
				elif CardHelper.SubType._2H in equip_card_resource.subtypes:
					return false
		elif is_off_hand:
			var hands_full : int = 0
			for equip_quantity_and_card_resource : Array in hero_and_equipment_cards.values():
				var equip_card_resource : CardResource = equip_quantity_and_card_resource[1]
				if CardHelper.SubType.Off_Hand in equip_card_resource.subtypes:
					return false
				if CardHelper.SubType._1H in equip_card_resource.subtypes:
					hands_full += 1
					if hands_full > 1:
						return false
				elif CardHelper.SubType._2H in equip_card_resource.subtypes:
					return false
	elif is_hero:
		for equip_quantity_and_card_resource : Array in hero_and_equipment_cards.values():
			var equip_card_resource : CardResource = equip_quantity_and_card_resource[1]
			for type : CardHelper.Type in card_resource.types:
					if type == CardHelper.Type.Hero:
						if type in equip_card_resource.types:
							return false
	return true

func populate_card_totals() -> void:
	var total_hero_equips : int = 0
	var total_inventory_cards : int = 0
	var total_main_deck_cards : int = 0
	for equip_quantity_and_card_resource : Array in hero_and_equipment_cards.values():
		total_hero_equips += equip_quantity_and_card_resource[0]
	for main_deck_quantity_and_card_resource : Array in main_cards.values():
		total_main_deck_cards += main_deck_quantity_and_card_resource[0]
	for inventory_quantity_and_card_resource : Array in inventory_cards.values():
		total_inventory_cards += inventory_quantity_and_card_resource[0]
	hero_arena_label.text = "Hero & Arena " + str(total_hero_equips)
	deck_label.text = "Deck " + str(total_main_deck_cards)
	inventory_label.text = "Inventory " + str(total_inventory_cards)
