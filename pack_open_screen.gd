extends Panel

@onready var grid_container: GridContainer = $ScrollContainer/GridContainer
@onready var scroll_container: ScrollContainer = $ScrollContainer

const CARD_OPENED_LABEL = preload("res://Resources/Cards/card_opened_label.tscn")
const CARD_FLIP_SCENE = preload("res://Resources/card_flip_scene.tscn")
@onready var next_pack_button: Button = $HBoxContainer2/NextPackButton
@onready var flip_cards_button: Button = $HBoxContainer2/FlipCardsButton
@onready var auto_flip_button: CheckButton = $HBoxContainer2/AutoFlipButton
@onready var open_remaining_button: Button = $HBoxContainer2/OpenRemainingButton
@onready var cards_opened_container: VBoxContainer = $ScrollContainer2/CardsOpenedContainer

@onready var fabled_labels: VBoxContainer = $ScrollContainer2/CardsOpenedContainer/Fabled
@onready var marvel_labels: VBoxContainer = $ScrollContainer2/CardsOpenedContainer/Marvel
@onready var legendary_labels: VBoxContainer = $ScrollContainer2/CardsOpenedContainer/Legendary
@onready var majestic_labels: VBoxContainer = $ScrollContainer2/CardsOpenedContainer/Majestic
@onready var super_rare_labels: VBoxContainer = $ScrollContainer2/CardsOpenedContainer/SuperRare
@onready var rare_labels: VBoxContainer = $ScrollContainer2/CardsOpenedContainer/Rare
@onready var common_labels: VBoxContainer = $ScrollContainer2/CardsOpenedContainer/Common
@onready var token_labels: VBoxContainer = $ScrollContainer2/CardsOpenedContainer/Token

@onready var add_binder_button: Button = $HBoxContainer/AddBinderButton
@onready var binder_list: OptionButton = $HBoxContainer/BinderList
@onready var save_cards_button: Button = $HBoxContainer/SaveCardsButton
@onready var save_as_cards_button: Button = $HBoxContainer/SaveAsCardsButton
@onready var include_tokens: CheckButton = $IncludeTokens

@onready var hover_panel: CardHoverPanel = $HoverPanel

#This is a 40% modifier to pull a short_print.
const short_print_majestic_rate : float = 0.65

var cards_saved : bool = false
var opened_card_labels : Dictionary = {}

func _ready() -> void:
	PackOpenHelper.opened_cards = {}
	await generate_pack()
	next_pack_button.pressed.connect(next_pack)
	flip_cards_button.pressed.connect(flip_all_cards)
	auto_flip_button.toggled.connect(autoflip_toggled)
	open_remaining_button.pressed.connect(open_remaining_packs)
	add_binder_button.pressed.connect(add_binder)
	save_cards_button.pressed.connect(save_cards)
	save_as_cards_button.pressed.connect(add_binder.bind(true))
	fill_binder_list()
	save_cards_button.disabled = true
	save_as_cards_button.disabled = true
	
func next_pack() -> void:
	for child : CardFlipScene in grid_container.get_children():
		if !child.is_flipped:
			return

	for child in grid_container.get_children():
		child.queue_free()
		
	if PackOpenHelper.packs_to_open == 1:
		save_cards_button.disabled = false
		save_as_cards_button.disabled = false
	
	if PackOpenHelper.packs_to_open > 0:
		scroll_container.scroll_vertical = 0
		await generate_pack()
	if auto_flip_button.button_pressed:
		flip_all_cards()

func flip_all_cards(flip_time : float = 0.30) -> void:
	for card : CardFlipScene in grid_container.get_children():
		await card.flip_card(flip_time)

func autoflip_toggled(toggled : bool) -> void:
	if toggled:
		flip_all_cards()

func open_remaining_packs() -> void:
	open_remaining_button.disabled = true
	next_pack_button.disabled = true
	for i in range(0, PackOpenHelper.packs_to_open):
		await flip_all_cards(0.02)
		await next_pack()
		save_cards_button.disabled = false
		save_as_cards_button.disabled = false
	await flip_all_cards(0.02)
	
func generate_pack() -> void:
	PackOpenHelper.packs_to_open -= 1
	var pack_commons : Array[CardResource] = PackOpenHelper.opening_pack_resource.generic_common_cards.duplicate()
	pack_commons.shuffle()

	for i in range( 0,PackOpenHelper.opening_pack_resource.generics_commons_per_pack ):
		var card_flip_scene : CardFlipScene = instantiate_card_scene()
		var card_resource = pack_commons.pop_back()
		if card_resource == null:
			printerr("Generated null card_resource for generic commons")
		card_flip_scene.card_resource = card_resource
		grid_container.add_child(card_flip_scene)

	var pack_class_commons : Array[CardResource] = PackOpenHelper.opening_pack_resource.class_common_cards.duplicate()
	pack_class_commons.shuffle()
	for i in range( 0, PackOpenHelper.opening_pack_resource.class_commons_per_pack ):
		var card_flip_scene : CardFlipScene = instantiate_card_scene()
		var card_resource = pack_class_commons.pop_back()
		if card_resource == null:
			printerr("Generated null card_resource for class commons")
		card_flip_scene.card_resource = card_resource
		grid_container.add_child(card_flip_scene)

	for i in range( 0, PackOpenHelper.opening_pack_resource.guaranteed_rares_per_pack ):
		var card_flip_scene : CardFlipScene = instantiate_card_scene()
		var card_resource = PackOpenHelper.opening_pack_resource.rare_cards.pick_random()
		if card_resource == null:
			printerr("Generated null card_resource for rares")
		card_flip_scene.card_resource = card_resource
		grid_container.add_child(card_flip_scene)

	for i in range( 0, PackOpenHelper.opening_pack_resource.equipment_per_pack ):
		var card_flip_scene : CardFlipScene = instantiate_card_scene()
		var card_resource = PackOpenHelper.opening_pack_resource.equipment_cards.pick_random()
		if card_resource == null:
			printerr("Generated null card_resource for equipment")
		card_flip_scene.card_resource = card_resource
		grid_container.add_child(card_flip_scene)
		
	for i in range( 0, PackOpenHelper.opening_pack_resource.juicer_rares_per_pack ):
		var card_flip_scene : CardFlipScene = instantiate_card_scene()
		match pick_random_high_rarity(PackOpenHelper.opening_pack_resource):
			CardHelper.Rarity.Majestic:
				var r = randf()
				var card_resource = PackOpenHelper.opening_pack_resource.majestic_cards.pick_random()
				if r >= short_print_majestic_rate and PackOpenHelper.opening_pack_resource.shortprint_majestic_cards.size() > 0:
					card_resource = PackOpenHelper.opening_pack_resource.shortprint_majestic_cards.pick_random()
					print("Pulled a short print majestic with a roll of " + str(r))
				if card_resource == null:
					printerr("Generated null card_resource for random high rarity - majestic")
				card_flip_scene.card_resource = card_resource
			CardHelper.Rarity.Super_Rare:
				var card_resource = PackOpenHelper.opening_pack_resource.super_rare_cards.pick_random()
				if card_resource == null:
					printerr("Generated null card_resource for random high rarity - super rare")
				card_flip_scene.card_resource = card_resource
			CardHelper.Rarity.Rare:
				var card_resource = PackOpenHelper.opening_pack_resource.rare_cards.pick_random()
				if card_resource == null:
					printerr("Generated null card_resource for random high rarity - rares")
				card_flip_scene.card_resource = card_resource
		
		grid_container.add_child(card_flip_scene)

	for i in range( 0, PackOpenHelper.opening_pack_resource.non_token_premium_foil_per_pack ):
		var card_flip_scene : CardFlipScene = instantiate_card_scene()
		var rarity : CardHelper.Rarity = pick_random_premium_foil_card(PackOpenHelper.opening_pack_resource)
		match rarity:
			CardHelper.Rarity.Fabled:
				var card_resource = PackOpenHelper.opening_pack_resource.fabled_cards.pick_random()
				if card_resource == null:
					printerr("Generated null card_resource for premium foil rarity - fabled")
				card_flip_scene.card_resource = card_resource
			CardHelper.Rarity.Legendary:
				var card_resource = PackOpenHelper.opening_pack_resource.legendary_cards.pick_random()
				if card_resource == null:
					printerr("Generated null card_resource for premium foil rarity - legendary")
				card_flip_scene.card_resource = card_resource
			CardHelper.Rarity.Marvel:
				var card_resource = PackOpenHelper.opening_pack_resource.marvel_cards.pick_random()
				if card_resource == null:
					printerr("Generated null card_resource for premium foil rarity - marvel")
				card_flip_scene.card_resource = card_resource
			CardHelper.Rarity.Majestic:
				var r = randf()
				var card_resource = PackOpenHelper.opening_pack_resource.majestic_cards.pick_random()
				if r >= short_print_majestic_rate and PackOpenHelper.opening_pack_resource.shortprint_majestic_cards.size() > 0:
					card_resource = PackOpenHelper.opening_pack_resource.shortprint_majestic_cards.pick_random()
					print("Pulled a short print majestic with a roll of " + str(r))
				if card_resource == null:
					printerr("Generated null card_resource for premium foil rarity - majestic")
				card_flip_scene.card_resource = card_resource
			CardHelper.Rarity.Super_Rare:
				var card_resource = PackOpenHelper.opening_pack_resource.super_rare_cards.pick_random()
				if card_resource == null:
					printerr("Generated null card_resource for premium foil rarity - super rare")
				card_flip_scene.card_resource = card_resource
			CardHelper.Rarity.Rare:
				var card_resource = PackOpenHelper.opening_pack_resource.rare_cards.pick_random()
				if card_resource == null:
					printerr("Generated null card_resource for premium foil rarity - rare")
				card_flip_scene.card_resource = card_resource
			CardHelper.Rarity.Common:
				if randf() <= 0.5:
					var card_resource = PackOpenHelper.opening_pack_resource.class_common_cards.pick_random()
					if card_resource == null:
						printerr("Generated null card_resource for premium foil rarity - class common")
					card_flip_scene.card_resource = card_resource
				else:
					var card_resource = PackOpenHelper.opening_pack_resource.generic_common_cards.pick_random()
					if card_resource == null:
						printerr("Generated null card_resource for premium foil rarity - generic common")
					card_flip_scene.card_resource = card_resource
		grid_container.add_child(card_flip_scene)

	var pack_tokens : Array[CardResource] = PackOpenHelper.opening_pack_resource.token_cards.duplicate()
	pack_tokens.shuffle()
	for i in range( 0, PackOpenHelper.opening_pack_resource.tokens_per_pack):
		var card_flip_scene : CardFlipScene = instantiate_card_scene()
		#Remove duplication of cards in pack.
		var card_resource = pack_tokens.pop_back()
		if PackOpenHelper.opening_pack_resource.expansion_slot_cards.size() > 0:
			var r : float = randf()
			var expansion_slot_weight : float = (1.0 / PackOpenHelper.opening_pack_resource.expansion_slot_rarity)
			if r < expansion_slot_weight:
				card_resource = PackOpenHelper.opening_pack_resource.expansion_slot_cards.pick_random()
				print("Pulled an expansion slot majestic with a roll of " + str(r) + " against weight " + str(expansion_slot_weight))
		if card_resource == null:
			printerr("Generated null card_resource for token")
		card_flip_scene.card_resource = card_resource
		grid_container.add_child(card_flip_scene)

	await get_tree().create_timer(0.01).timeout

func pick_random_high_rarity(pack_resource: PackResource) -> CardHelper.Rarity:
	#print("Rolling for R/S/M")
	var rarities : Array[CardHelper.Rarity] = []
	var weights : Array[float] = []

	# Only include rarities that exist in this set (pull rate > 0 and card array not empty)
	if pack_resource.super_rare_rarity > 0 and pack_resource.super_rare_cards.size() > 0:
		rarities.push_front(CardHelper.Rarity.Super_Rare)
		weights.push_front(1.0 / pack_resource.super_rare_rarity)
	if pack_resource.majestic_rarity > 0 and pack_resource.majestic_cards.size() > 0:
		rarities.push_front(CardHelper.Rarity.Majestic)
		weights.push_front(1.0 / pack_resource.majestic_rarity)

	# Weighted random selection
	var r = randf()
	var acc = 0.0
	for i in range(rarities.size()):
		acc = weights[i]
		if r < acc:
			print("Juicer hit: rolled a " + str(r) + " against acc of " + str(acc))
			return rarities[i]

	return CardHelper.Rarity.Rare

func pick_random_premium_foil_card(pack_resource: PackResource) -> CardHelper.Rarity:
	#print("rolling for premium foil.")
	var rarities : Array[CardHelper.Rarity] = []
	var weights : Array[float] = []

	# Only include rarities that exist in this set (pull rate > 0 and card array not empty)
	if pack_resource.foil_rare_rarity > 0 and pack_resource.rare_cards.size() > 0:
		rarities.push_front(CardHelper.Rarity.Rare)
		weights.push_front(1.0 / pack_resource.foil_rare_rarity)
	if pack_resource.super_rare_rarity > 0 and pack_resource.super_rare_cards.size() > 0:
		rarities.push_front(CardHelper.Rarity.Super_Rare)
		weights.push_front(1.0 / pack_resource.foil_super_rare_rarity)
		#print("Super rare odds in decimal are " + str(1.0 / pack_resource.super_rare_rarity))
	if pack_resource.majestic_rarity > 0 and pack_resource.majestic_cards.size() > 0:
		rarities.push_front(CardHelper.Rarity.Majestic)
		weights.push_front(1.0 / pack_resource.foil_majestic_rarity)
		#print("Majestic odds in decimal are " + str(1.0 / pack_resource.majestic_rarity))
	if pack_resource.legendary_rarity > 0 and pack_resource.legendary_cards.size() > 0:
		rarities.push_front(CardHelper.Rarity.Legendary)
		weights.push_front(1.0 / pack_resource.legendary_rarity)
		#print("Legendary odds in decimal are " + str(1.0 / pack_resource.legendary_rarity))
	if pack_resource.marvel_rarity > 0 and pack_resource.marvel_cards.size() > 0:
		rarities.push_front(CardHelper.Rarity.Marvel)
		weights.push_front(1.0 / pack_resource.marvel_rarity)
		#print("Legendary odds in decimal are " + str(1.0 / pack_resource.legendary_rarity))
	if pack_resource.fabled_rarity > 0 and pack_resource.fabled_cards.size() > 0:
		rarities.push_front(CardHelper.Rarity.Fabled)
		weights.push_front(1.0 / pack_resource.fabled_rarity)
		#print("Fabled odds in decimal are " + str(1.0 / pack_resource.fabled_rarity))
	# Weighted random selection
	var r = randf()
	var acc = 0.0
	for i in range(rarities.size()):
		#print(str(weights[i]) + " " + CardHelper.Rarity.keys()[rarities[i]])
		acc = weights[i]
		if r < acc:
			print("Juicer hit: rolled a " + str(r) + " against acc of " + str(acc))
			return rarities[i]

	return CardHelper.Rarity.Common

func show_hover_panel(card_resource : CardResource) -> void:
	hover_panel.show()
	hover_panel.set_card_resource(card_resource)

func hide_hover_panel(_card_resource : CardResource) -> void:
	hover_panel.hide()

func instantiate_card_scene() -> CardFlipScene:
	var card_flip_scene : CardFlipScene = CARD_FLIP_SCENE.instantiate()
	card_flip_scene.card_hovered.connect(show_hover_panel)
	card_flip_scene.card_unhovered.connect(hide_hover_panel)
	card_flip_scene.card_flipped.connect(card_flipped_handler)
	return card_flip_scene

func add_binder(and_save_cards : bool = false) -> void:
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
			binder.resource_name = binder_name
			var resource_path = "user://BinderResources/" + binder_name + ".res"
			var dir : DirAccess = DirAccess.open("user://")
			if !dir.file_exists(resource_path):
				ResourceSaver.save(binder, resource_path)
			BinderHelper.binders[binder_name] = binder
			var saved_binder_index : int = BinderHelper.binders.keys().find(binder_name)
			fill_binder_list()
			binder_list.select(saved_binder_index + 1)
			if and_save_cards and binder_list.selected != 0:
				save_cards()
		popup.queue_free())
		
func save_cards() -> void:
	var selected_idx = binder_list.selected
	if selected_idx == 0:
		var dialog = AcceptDialog.new()
		dialog.dialog_text = "No binder selected to save cards to."
		dialog.title = "Warning"
		add_child(dialog)
		dialog.popup_centered()
		await dialog.confirmed
		return
	var binder_name : String = binder_list.get_item_text(selected_idx)
	var binder_path : String = "user://BinderResources/" + binder_name + ".res"
	var binder : BinderResource = ResourceLoader.load(binder_path)
	if binder == null:
		print("Binder resource not found: " + binder_path)
		return
	for card_key : String in PackOpenHelper.opened_cards.keys():
		if binder.cards.has(card_key):
			binder.cards[card_key][0] += PackOpenHelper.opened_cards[card_key][0]
		else:
			binder.cards[card_key] = PackOpenHelper.opened_cards[card_key]
	if include_tokens.button_pressed:
		for card_resource : CardResource in PackOpenHelper.opening_pack_resource.token_cards:
			binder.cards[card_resource.id] = [3, card_resource]
	ResourceSaver.save(binder, binder.resource_path)
	cards_saved = true
	var dialog = AcceptDialog.new()
	dialog.dialog_text = "Cards saved to binder."
	dialog.title = "Success"
	add_child(dialog)
	dialog.popup_centered()
	await dialog.confirmed
	return

func fill_binder_list() -> void:
	binder_list.clear()
	binder_list.add_item("")
	for binder_index : int in BinderHelper.binders.size():
		var binder_name : String = BinderHelper.binders.keys()[binder_index]
		var binder_resource : BinderResource = BinderHelper.binders[binder_name]
		if binder_resource != null and binder_name != "":
			binder_list.add_item(binder_name, binder_index + 1)

func _on_main_menu_button_pressed() -> void:
	if !cards_saved:
		var confirmation_dialog = ConfirmationDialog.new()
		confirmation_dialog.dialog_text = "Are you sure you want to leave without saving cards?"
		confirmation_dialog.title = "Warning"
		add_child(confirmation_dialog)
		confirmation_dialog.popup_centered()
		confirmation_dialog.confirmed.connect(SceneChanger.switch_to_main_menu_scene)
	else:
		SceneChanger.switch_to_main_menu_scene()

func card_flipped_handler(card_resource : CardResource) -> void:
	if PackOpenHelper.opened_cards.has(card_resource.id):
		PackOpenHelper.opened_cards[card_resource.id][0] += 1
		var label : Label = opened_card_labels[card_resource.id]
		label.text = str(PackOpenHelper.opened_cards[card_resource.id][0]) + "x " + card_resource.name
	else:
		PackOpenHelper.opened_cards.set(card_resource.id, [1, card_resource])
		var new_label : Label  = CARD_OPENED_LABEL.instantiate()
		new_label.text = "1x " + card_resource.name
		new_label.name = card_resource.id
		add_label_to_rarity_child(card_resource, new_label)
		opened_card_labels[card_resource.id] = new_label
		
func add_label_to_rarity_child(card_resource, new_label) -> void:
	match card_resource.rarity:
		CardHelper.Rarity.Common:
			common_labels.add_child(new_label)
		CardHelper.Rarity.Token:
			token_labels.add_child(new_label)
		CardHelper.Rarity.Rare:
			rare_labels.add_child(new_label)
		CardHelper.Rarity.Super_Rare:
			super_rare_labels.add_child(new_label)
			if !super_rare_labels.visible:
				super_rare_labels.show()
		CardHelper.Rarity.Majestic:
			majestic_labels.add_child(new_label)
		CardHelper.Rarity.Legendary:
			legendary_labels.add_child(new_label)
		CardHelper.Rarity.Marvel:
			marvel_labels.add_child(new_label)
		CardHelper.Rarity.Fabled:
			fabled_labels.add_child(new_label)
