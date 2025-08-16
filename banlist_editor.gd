extends Control

class_name BanlistEditor

@onready var hero_ll_list_grid_container: GridContainer = $ScrollContainer/VBoxContainer/HeroLLList
@onready var banned_cards_grid_container: GridContainer = $ScrollContainer/VBoxContainer/BannedCards

@onready var binder_cards : BinderCards = $BinderCards

@onready var hover_panel: CardHoverPanel = $HoverPanel

@onready var add_banlist_button: Button = $HBoxContainer/AddBanlistButton
@onready var banlist_list_options: OptionButton = $HBoxContainer/BanlistListOptions
@onready var save_banlist_button: Button = $HBoxContainer/SaveBanlistButton
@onready var save_banlist_as_button: Button = $HBoxContainer/SaveBanlistAsButton
@onready var export_banlist_button: Button = $HBoxContainer/ExportBanlistButton
@onready var delete_banlist_button: Button = $HBoxContainer/DeleteBanlistbutton
@onready var main_menu_button: Button = $MainMenuButton


const HERO_LL_ENTRY = preload("res://Resources/Banlists/hero_ll_entry.tscn")
const DECK_CARD = preload("res://DeckEditor/deck_card.tscn")

var banned_cards : Dictionary[String, CardResource] = {}
var hero_ll_list : Dictionary[String, int] = {}
var current_banlist : BanlistResource

func _ready() -> void:
	fill_banlist_list()
	add_hero_lls()
	
	add_banlist_button.pressed.connect(add_new_banlist)
	save_banlist_button.pressed.connect(save_cards_to_banlist)
	save_banlist_as_button.pressed.connect(add_new_banlist.bind(true))
	export_banlist_button.pressed.connect(export_banlist)
	delete_banlist_button.pressed.connect(delete_banlist)
	main_menu_button.pressed.connect(SceneChanger.switch_to_main_menu_scene)
	binder_cards.add_card_to_banlist.connect(add_card_to_banlist)
	binder_cards.show_hover_panel.connect(show_hover_panel)
	binder_cards.hide_hover_panel.connect(hide_hover_panel)
	save_banlist_button.disabled = true
	export_banlist_button.disabled = true
	banlist_list_options.item_selected.connect(func(selected_idx):
		if selected_idx != 0:
			load_cards_from_banlist()
			save_banlist_button.disabled = false
			export_banlist_button.disabled = false
		else:
			save_banlist_button.disabled = true
			export_banlist_button.disabled = true
	)
	binder_cards.load_binder("user://BinderResources/all_cards.res")
			
func show_hover_panel(card_resource : CardResource) -> void:
	hover_panel.show()
	hover_panel.set_card_resource(card_resource)

func hide_hover_panel(_card_resource : CardResource) -> void:
	hover_panel.hide()

func _on_main_menu_button_pressed() -> void:
	SceneChanger.switch_to_main_menu_scene()
	
func add_card_to_banlist(card_resource : CardResource):
	var types = card_resource.types
	var card_id = card_resource.id
	if banned_cards.has(card_id):
		print("Cannot add that many of this card.")
		return
	else:
		banned_cards[card_id] = card_resource
		var banlist_card_scene : DeckCard = DECK_CARD.instantiate()
		banlist_card_scene.name = card_id
		banlist_card_scene.card_location = DeckHelper.CardLocation.BANLIST
		banlist_card_scene.card_resource = card_resource
		banlist_card_scene.card_hovered.connect(show_hover_panel)
		banlist_card_scene.card_unhovered.connect(hide_hover_panel)
		banlist_card_scene.card_remove.connect(remove_card)
		banned_cards_grid_container.add_child(banlist_card_scene)
		banlist_card_scene.set_card_quantity(1)
			
func fill_banlist_list() -> void:
	banlist_list_options.clear()
	banlist_list_options.add_item("")
	for banlist_index : int in BanlistHelper.banlists.size():
		var banlist_name : String = BanlistHelper.banlists.keys()[banlist_index]
		var banlist_resource : BanlistResource = BanlistHelper.banlists[banlist_name]
		if banlist_resource != null and banlist_name != "":
			banlist_list_options.add_item(banlist_name, banlist_index + 1)

func add_new_banlist(and_save_banlist : bool = false) -> void:
	var popup = Popup.new()
	popup.title = "Create Banlist"
	popup.min_size = Vector2(300, 100)

	var vbox = VBoxContainer.new()
	vbox.position = Vector2(20,0)
	vbox.custom_minimum_size = Vector2(250, 90)
	var label = Label.new()
	label.text = "Banlist Name:"
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
		var banlist_name = name_edit.text.strip_edges()
		if banlist_name != "":
			var banlist = BanlistResource.new()
			var dir : DirAccess = DirAccess.open("user://")
			banlist.resource_name = banlist_name
			banlist.name = banlist_name
			var resource_path = "user://BanlistResources/" + banlist_name + ".res"
			if !dir.file_exists(resource_path):
				ResourceSaver.save(banlist, resource_path)
			BanlistHelper.banlists[banlist_name] = banlist
			var saved_banlist_index : int = BanlistHelper.banlists.keys().find(banlist_name)
			fill_banlist_list()
			banlist_list_options.select(saved_banlist_index + 1)
			if and_save_banlist and banlist_list_options.selected != 0:
				save_cards_to_banlist()
			banlist_list_options.item_selected.emit(banlist_list_options.selected)
		popup.queue_free())
	
func save_cards_to_banlist() -> void:
	var selected_idx = banlist_list_options.selected
	if selected_idx == -1:
		var dialog = AcceptDialog.new()
		dialog.dialog_text = "No banlist selected to save cards to."
		dialog.title = "Warning"
		add_child(dialog)
		dialog.popup_centered()
		await dialog.confirmed
		return
	var banlist_name : String = banlist_list_options.get_item_text(selected_idx)
	var banlist_path : String = "user://BanlistResources/" + banlist_name + ".res"
	var banlist : BanlistResource = ResourceLoader.load(banlist_path)
	if banlist == null:
		print("Banlist resource not found: " + banlist_path)
		return
	banlist.clear_banlist()
	for card_id : String in banned_cards:
		banlist.cards[card_id] = banned_cards[card_id]
	for hero_entry : HeroLLEntry in hero_ll_list_grid_container.get_children():
		banlist.heroes[hero_entry.name] = hero_entry.get_hero_points()

	ResourceSaver.save(banlist, banlist.resource_path)

func load_cards_from_banlist() -> void:
	var selected_idx = banlist_list_options.get_selected_id()
	if selected_idx == 0:
		var dialog = AcceptDialog.new()
		dialog.dialog_text = "No banlist selected to load from."
		dialog.title = "Warning"
		add_child(dialog)
		dialog.popup_centered()
		await dialog.confirmed
		return
	var banlist_name : String = banlist_list_options.get_item_text(selected_idx)
	var banlist_path : String = "user://BanlistResources/" + banlist_name + ".res"
	var banlist : BanlistResource = ResourceLoader.load(banlist_path)
	if banlist == null:
		print("Banlist resource not found: " + banlist_path)
		return
	
	remove_all_cards()
	remove_all_hero_lls()
	for card_resource : CardResource in banlist.cards.values():
		add_card_to_banlist(card_resource)
	for hero : String in banlist.heroes:
		var hero_ll_node : HeroLLEntry = hero_ll_list_grid_container.get_node_or_null(hero)
		if hero_ll_node:
			hero_ll_node.set_hero_points(banlist.heroes[hero])

func add_hero_lls() -> void:
	for hero_name : String in CardHelper.Hero.keys():
		var hero_entry : HeroLLEntry = HERO_LL_ENTRY.instantiate()
		hero_entry.name = hero_name
		hero_entry.set_hero_points(0)
		hero_entry.set_hero_label(hero_name)
		hero_ll_list_grid_container.add_child(hero_entry)

func remove_all_hero_lls() -> void:
	for child : HeroLLEntry in hero_ll_list_grid_container.get_children():
		child.set_hero_points(0)
	hero_ll_list.clear()
		
func remove_card(card_scene : DeckCard) -> void:
	var new_quantity: int = 0
	match card_scene.card_location:
		DeckHelper.CardLocation.BANLIST:
			if banned_cards.has(card_scene.card_resource.id):
				banned_cards.erase(card_scene.card_resource.id)
	card_scene.queue_free()

func remove_all_cards() -> void:
	for card_scene :DeckCard in banned_cards_grid_container.get_children():
		remove_card(card_scene)
	
func export_banlist() -> void:
	var selected_idx = banlist_list_options.get_selected_id()
	if selected_idx == -1:
		var dialog = AcceptDialog.new()
		dialog.dialog_text = "No banlist selected to export"
		dialog.title = "Warning"
		add_child(dialog)
		dialog.popup_centered()
		await dialog.confirmed
		return
	var banlist_name : String = banlist_list_options.get_item_text(selected_idx)
	var banlist_path : String = "user://BanlistResources/" + banlist_name + ".res"
	var banlist : BanlistResource = ResourceLoader.load(banlist_path)
	if banlist == null:
		print("Banlist resource not found: " + banlist_path)
		return
	
	var banlist_string = "Banlist cards\n"
	for card_resource : CardResource in banlist.cards.values():
		banlist_string += str(card_resource.name) + "\n"
	banlist_string += "Hero LL Leaderboard\n"
	for hero_entry : String in banlist.heroes.keys():
		if banlist.heroes[hero_entry] != 0:
			if banlist.heroes[hero_entry] >= 10:
				banlist_string += hero_entry + "= LIVING LEGEND" + "\n"
			else:
				banlist_string += hero_entry + "=" + str(banlist.heroes[hero_entry]) + "\n"
	DisplayServer.clipboard_set(banlist_string)
	var dialog = AcceptDialog.new()
	dialog.dialog_text = "Saved banlist set to clipboard."
	dialog.title = "Success"
	add_child(dialog)
	dialog.popup_centered()
	await dialog.confirmed
	return

func delete_banlist() -> void:
	var selected_idx = banlist_list_options.get_selected_id()
	if selected_idx == -1:
		var dialog = AcceptDialog.new()
		dialog.dialog_text = "No banlist selected to export"
		dialog.title = "Warning"
		add_child(dialog)
		dialog.popup_centered()
		await dialog.confirmed
		return
	var banlist_name : String = banlist_list_options.get_item_text(selected_idx)
	var banlist_path : String = "user://BanlistResources/" + banlist_name + ".res"
	
	var dialog = ConfirmationDialog.new()
	dialog.dialog_text = "Delete selected banlist?"
	dialog.title = "Really delete?"
	add_child(dialog)
	dialog.popup_centered()
	dialog.confirmed.connect(func(): 
		DirAccess.remove_absolute(banlist_path)
		BanlistHelper.banlists.erase(banlist_name)
		fill_banlist_list()
		remove_all_cards()
		remove_all_hero_lls()
	)
	
	return
