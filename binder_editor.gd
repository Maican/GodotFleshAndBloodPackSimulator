extends Control

class_name BinderEditor

@onready var binder_cards_grid_container: GridContainer = $ScrollContainer/VBoxContainer/BinderCardsGrid

@onready var binder_cards : BinderCards = $BinderCards

@onready var hover_panel: CardHoverPanel = $HoverPanel
@onready var banlist_list: OptionButton = $BanlistList

@onready var add_binder_button: Button = $HBoxContainer/AddBinderButton
@onready var binder_list_options: OptionButton = $HBoxContainer/BinderListOptions
@onready var save_binder_button: Button = $HBoxContainer/SaveBinderButton
@onready var save_binder_as_button: Button = $HBoxContainer/SaveBinderAsButton
@onready var export_binder_button: Button = $HBoxContainer/ExportBinderButton
@onready var delete_binder_button: Button = $HBoxContainer/DeleteBinderbutton
@onready var main_menu_button: Button = $MainMenuButton

const DECK_CARD = preload("res://DeckEditor/deck_card.tscn")

var selected_binder_cards : Dictionary[String, Array] = {}
var hero_ll_list : Dictionary[String, int] = {}
var current_binder : BinderResource
var current_banlist : BanlistResource

func _ready() -> void:
	fill_binder_list()
	fill_banlist_list()
	banlist_list.item_selected.connect(set_banlist)
	banlist_list.item_selected.connect(binder_cards.set_banlist.bind(banlist_list))
	add_binder_button.pressed.connect(add_new_binder)
	save_binder_button.pressed.connect(save_cards_to_binder)
	save_binder_as_button.pressed.connect(add_new_binder.bind(true))
	export_binder_button.pressed.connect(export_binder)
	delete_binder_button.pressed.connect(delete_binder)
	main_menu_button.pressed.connect(SceneChanger.switch_to_main_menu_scene)
	binder_cards.add_card_to_binder.connect(add_card_to_binder)
	binder_cards.show_hover_panel.connect(show_hover_panel)
	binder_cards.hide_hover_panel.connect(hide_hover_panel)
	save_binder_button.disabled = true
	export_binder_button.disabled = true
	binder_list_options.item_selected.connect(func(selected_idx):
		if selected_idx != 0:
			load_cards_from_binder()
			save_binder_button.disabled = false
			export_binder_button.disabled = false
		else:
			save_binder_button.disabled = true
			export_binder_button.disabled = true
	)
	binder_cards.load_binder("user://BinderResources/all_cards.res")
			
func fill_banlist_list() -> void:
	banlist_list.clear()
	banlist_list.add_item("")
	for banlist_index : int in BanlistHelper.banlists.size():
		var banlist_name : String = BanlistHelper.banlists.keys()[banlist_index]
		var banlist_resource : BanlistResource = BanlistHelper.banlists[banlist_name]
		if banlist_resource != null and banlist_name != "":
			banlist_list.add_item(banlist_name, banlist_index + 1)
			
func show_hover_panel(card_resource : CardResource) -> void:
	hover_panel.show()
	hover_panel.set_card_resource(card_resource)

func hide_hover_panel(_card_resource : CardResource) -> void:
	hover_panel.hide()
	
func add_card_to_binder(quantity_and_card_array: Array):
	var quantity : int = quantity_and_card_array[0]
	var card_resource : CardResource = quantity_and_card_array[1]

	var card_id = card_resource.id
	if selected_binder_cards.has(card_id):
		if selected_binder_cards[card_id][0] + quantity > 3:
			print("Cannot add that many of this card.")
			return
		selected_binder_cards[card_id][0] += quantity
		var card_scene : DeckCard = binder_cards_grid_container.get_node(card_id)
		if card_scene:
			card_scene.set_card_quantity(selected_binder_cards[card_id][0])
	else:
		selected_binder_cards[card_id] = [quantity, card_resource]
		var deck_card_scene : DeckCard = DECK_CARD.instantiate()
		deck_card_scene.name = card_id
		deck_card_scene.card_location = DeckHelper.CardLocation.BINDER
		deck_card_scene.card_resource = card_resource
		deck_card_scene.card_hovered.connect(show_hover_panel)
		deck_card_scene.card_unhovered.connect(hide_hover_panel)
		deck_card_scene.card_remove.connect(remove_card)
		binder_cards_grid_container.add_child(deck_card_scene)
		if current_banlist:
			if card_id in current_banlist.cards.keys():
				deck_card_scene.ban_card()
		deck_card_scene.set_card_quantity(quantity)

func fill_binder_list() -> void:
	binder_list_options.clear()
	binder_list_options.add_item("")
	for new_binder_name : String in BinderHelper.binders.keys():
		if new_binder_name != "all_cards":
			var new_binder : BinderResource = BinderHelper.binders[new_binder_name]
			if new_binder != null and new_binder.resource_name != "":
				binder_list_options.add_item(new_binder.resource_name)

func add_new_binder(and_save_binder : bool = false) -> void:
	var popup = Popup.new()
	popup.title = "Create Binder"
	popup.min_size = Vector2(300, 100)

	var vbox = VBoxContainer.new()
	vbox.position = Vector2(20,0)
	vbox.custom_minimum_size = Vector2(250, 90)
	var label = Label.new()
	label.text = "Binder Name:"
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
		var binder_name = name_edit.text.strip_edges()
		if binder_name != "":
			var binder = BinderResource.new()
			var dir : DirAccess = DirAccess.open("user://")
			binder.resource_name = binder_name
			binder.name = binder_name
			var resource_path = "user://BinderResources/" + binder_name + ".res"
			if !dir.file_exists(resource_path):
				ResourceSaver.save(binder, resource_path)
			BinderHelper.binders[binder_name] = binder
			var saved_binder_index : int = BinderHelper.binders.keys().find(binder_name)
			fill_binder_list()
			binder_list_options.select(saved_binder_index)
			if and_save_binder and binder_list_options.selected != 0:
				save_cards_to_binder()
			binder_list_options.item_selected.emit(binder_list_options.selected)
		popup.queue_free())
	
func save_cards_to_binder() -> void:
	var selected_idx = binder_list_options.selected
	if selected_idx == -1:
		var dialog = AcceptDialog.new()
		dialog.dialog_text = "No binder selected to save cards to."
		dialog.title = "Warning"
		add_child(dialog)
		dialog.popup_centered()
		await dialog.confirmed
		return
	var binder_name : String = binder_list_options.get_item_text(selected_idx)
	var binder_path : String = "user://BinderResources/" + binder_name + ".res"
	var binder : BinderResource = ResourceLoader.load(binder_path)
	if binder == null:
		print("Binder resource not found: " + binder_path)
		return

	binder.clear_binder()
	for card_id : String in selected_binder_cards.keys():
		binder.cards[card_id] = selected_binder_cards[card_id]

	ResourceSaver.save(binder, binder.resource_path)

func load_cards_from_binder() -> void:
	var selected_idx = binder_list_options.get_selected_id()
	if selected_idx == 0:
		var dialog = AcceptDialog.new()
		dialog.dialog_text = "No binder selected to load from."
		dialog.title = "Warning"
		add_child(dialog)
		dialog.popup_centered()
		await dialog.confirmed
		return
	var binder_name : String = binder_list_options.get_item_text(selected_idx)
	var binder_path : String = "user://binderResources/" + binder_name + ".res"
	var binder : BinderResource = ResourceLoader.load(binder_path)
	if binder == null:
		print("Binder resource not found: " + binder_path)
		return
	
	remove_all_cards()
	for card_id : String in binder.cards.keys():
		var card_resource : CardResource = binder.cards[card_id][1]
		var card_quantity : int = binder.cards[card_id][0]
		add_card_to_binder([card_quantity, card_resource])

func remove_card(card_scene : DeckCard) -> void:
	var new_quantity: int = 0
	match card_scene.card_location:
		DeckHelper.CardLocation.BINDER:
			if selected_binder_cards.has(card_scene.card_resource.id):
				selected_binder_cards.erase(card_scene.card_resource.id)
	card_scene.queue_free()

func remove_all_cards() -> void:
	for card_scene :DeckCard in binder_cards_grid_container.get_children():
		remove_card(card_scene)
	
func export_binder() -> void:
	var selected_idx = binder_list_options.get_selected_id()
	if selected_idx == -1:
		var dialog = AcceptDialog.new()
		dialog.dialog_text = "No binder selected to export"
		dialog.title = "Warning"
		add_child(dialog)
		dialog.popup_centered()
		await dialog.confirmed
		return
	var binder_name : String = binder_list_options.get_item_text(selected_idx)
	var binder_path : String = "user://binderResources/" + binder_name + ".res"
	var binder : BinderResource = ResourceLoader.load(binder_path)
	if binder == null:
		print("Binder resource not found: " + binder_path)
		return
	
	var binder_string = "Binder cards\n"
	for card_id : String in binder.cards.keys():
		binder_string += str(card_id) + "\n"
	DisplayServer.clipboard_set(binder_string)
	var dialog = AcceptDialog.new()
	dialog.dialog_text = "Saved binder set to clipboard."
	dialog.title = "Success"
	add_child(dialog)
	dialog.popup_centered()
	await dialog.confirmed
	return

func delete_binder() -> void:
	var selected_idx = binder_list_options.get_selected_id()
	if selected_idx == -1:
		var dialog = AcceptDialog.new()
		dialog.dialog_text = "No binder selected to export"
		dialog.title = "Warning"
		add_child(dialog)
		dialog.popup_centered()
		await dialog.confirmed
		return
	var binder_name : String = binder_list_options.get_item_text(selected_idx)
	var binder_path : String = "user://BinderResources/" + binder_name + ".res"
	
	var dialog = ConfirmationDialog.new()
	dialog.dialog_text = "Delete selected binder?"
	dialog.title = "Really delete?"
	add_child(dialog)
	dialog.popup_centered()
	dialog.confirmed.connect(func(): 
		DirAccess.remove_absolute(binder_path)
		BinderHelper.binders.erase(binder_name)
		fill_binder_list()
		remove_all_cards()
	)
	
	return

func set_banlist(index : int) -> void:
	if index <= 0:
		current_banlist = null
		get_tree().call_group("bannable_card", "check_if_banned", null)
		return
	var banlist_name : String = banlist_list.get_item_text(index)
	var banlist : BanlistResource = BanlistHelper.banlists.get(banlist_name)
	current_banlist = banlist
	get_tree().call_group("bannable_card", "check_if_banned", banlist)
