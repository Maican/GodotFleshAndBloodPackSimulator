extends Control

class_name BinderCards

signal scrolled
signal show_hover_panel
signal hide_hover_panel
signal add_card_to_inventory
signal add_card_to_main
signal add_card_to_maybe

@onready var binder_cards_scroll: ScrollContainer = $BinderCardsScroll
@onready var binder_cards_v_box: VBoxContainer = $BinderCardsScroll/BinderCardsVBox
@onready var search_box: LineEdit = $HBoxContainer/SearchBox
@onready var sort_list: OptionButton = $HBoxContainer/SortList
@onready var filter_button: TextureButton = $HBoxContainer/FilterButton
@onready var filter_panel: FilterPanel = $FilterPanel

@onready var clear_filters_button: Button = $FilterPanel/ClearFiltersButton

const BINDER_CARD = preload("res://DeckEditor/binder_card.tscn")

var loaded_binder_card_scenes : Dictionary[String, BinderCard] = {}

var binder : BinderResource
var filtered_binder_card_resources : Array[CardResource] = []

var previous_scroll_vertical : int = 0

var batch_size := 10
var max_loaded := 100
var first_visible_index := 0
const SCROLL_BUFFER := 1500

var current_sort_index : int = 0
var current_search_text : String = ""

func _ready() -> void:
	scrolled.emit(binder_cards_scroll.get_global_rect())
	sort_list.item_selected.connect(sort_binder_cards)
	search_box.text_submitted.connect(search_binder_cards)
	filter_panel.filters_changed.connect(update_binder_display)
	filter_button.toggled.connect(func(_toggled):
		filter_panel.visible = filter_button.button_pressed
	)
	search_box.text_changed.connect(func(new_text : String): 
		if new_text.is_empty() or new_text == null:
			search_binder_cards("")
	)

func _input(event) -> void:
	if filter_panel.visible and event is InputEventMouseButton and event.pressed:
		var mouse_pos = get_viewport().get_mouse_position()
		var panel_rect = filter_panel.get_global_rect()
		if not panel_rect.has_point(mouse_pos):
			await get_tree().create_timer(0.1).timeout
			filter_panel.hide()
			filter_button.button_pressed = false

	if binder_cards_scroll.scroll_vertical != previous_scroll_vertical:
		await get_tree().create_timer(0.01).timeout
		scrolled.emit(binder_cards_scroll.get_global_rect())
		_on_scroll_changed()
	previous_scroll_vertical = binder_cards_scroll.scroll_vertical

func update_visible_cards():
	var end_index = min(first_visible_index + max_loaded, filtered_binder_card_resources.size())
	var before_msec : int = Time.get_ticks_msec()
	for child : BinderCard in loaded_binder_card_scenes.values():
		child.hide()
	
	for i in range(first_visible_index, end_index):
		var card_resource = filtered_binder_card_resources[i]
		var card_id = card_resource.id
		if loaded_binder_card_scenes.has(card_id):
			loaded_binder_card_scenes[card_id].show()
		else:
			var card_scene : BinderCard = BINDER_CARD.instantiate()
			card_scene.card_resource = card_resource
			card_scene.quantity = binder.cards[card_id][0]
			card_scene.card_hovered.connect(show_hover_panel.emit)
			card_scene.card_unhovered.connect(hide_hover_panel.emit)
			card_scene.card_add_to_inventory.connect(add_card_to_inventory.emit)
			card_scene.card_add_to_main.connect(add_card_to_main.emit)
			card_scene.card_add_to_maybe.connect(add_card_to_maybe.emit)
			scrolled.connect(card_scene.should_load_texture)
			binder_cards_v_box.add_child(card_scene)
			card_scene.name = card_id
			loaded_binder_card_scenes[card_id] = card_scene
	await get_tree().create_timer(0.001).timeout
	scrolled.emit(binder_cards_scroll.get_global_rect())

func _on_scroll_changed():
	var scroll_pos = binder_cards_scroll.scroll_vertical
	var max_scroll = binder_cards_scroll.get_v_scroll_bar().max_value
	# If near the end, load next batch
	if scroll_pos > max_scroll - SCROLL_BUFFER and first_visible_index + max_loaded <= filtered_binder_card_resources.size():
		first_visible_index += batch_size
		update_visible_cards()
		binder_cards_scroll.scroll_vertical -= SCROLL_BUFFER
	# If near the start, cull beginning
	elif scroll_pos < SCROLL_BUFFER and first_visible_index > 0:
		first_visible_index = max(first_visible_index - batch_size, 0)
		update_visible_cards()
		binder_cards_scroll.scroll_vertical += SCROLL_BUFFER

func binder_selected(index: int, binder_list : OptionButton) -> void:
	if index <= 0:
		return
	var binder_name : String = binder_list.get_item_text(index)
	for child : BinderCard in loaded_binder_card_scenes.values():
		child.queue_free()
	filtered_binder_card_resources.clear()
	loaded_binder_card_scenes.clear()
	var binder_path : String = "user://BinderResources/" + binder_name + ".res"
	binder = ResourceLoader.load(binder_path)

	for key : String in binder.cards:
		filtered_binder_card_resources.append(binder.cards[key][1])

	filtered_binder_card_resources.sort_custom(func(a:CardResource, b:CardResource):
		return a.name < b.name
	)

	first_visible_index = 0
	# Only load the first batch
	update_visible_cards()
	binder_cards_scroll.scroll_vertical = 0

func update_binder_display() -> void:
	first_visible_index = 0
	binder_cards_scroll.scroll_vertical = 0
	if binder == null:
		return
	for key : String in binder.cards:
		filtered_binder_card_resources.append(binder.cards[key][1])
	
	var filter_map = filter_panel.current_filters

	for key in filter_map.keys():
		var filter_map_array : Array = filter_map[key]
		if filter_map_array.size() > 1:
			var filter_field : Dictionary = filter_map[key][0]
			var filter_values : Array = filter_map[key][1]
			if filter_values.size() > 0:
				filtered_binder_card_resources = filtered_binder_card_resources.filter(func(binder_card:CardResource):
					for card_value in binder_card.get(key):
						if card_value in filter_values:
							return true
					return false
				)
		
	var numerical_filter_map = filter_panel.current_numerical_filters
	for key in numerical_filter_map.keys():
		var filter_value = numerical_filter_map[key]
		# Skip if no filter selected or filter is empty string
		if filter_value == -1:
			continue
		filtered_binder_card_resources = filtered_binder_card_resources.filter(func(binder_card:CardResource):
			return binder_card.get(key) == filter_value
		)
	# Search
	var search_text = current_search_text.strip_edges().to_lower()
	if search_text != "":
		filtered_binder_card_resources = filtered_binder_card_resources.filter(func(binder_card:CardResource):
			return (
				binder_card.card_effect.to_lower().find(search_text) != -1 or
				binder_card.name.to_lower().find(search_text) != -1 or
				binder_card.classes.has(CardHelper.Class.get(search_text) if CardHelper.Class.has(search_text) else -1) or
				binder_card.types.has(CardHelper.Type.get(search_text) if CardHelper.Type.has(search_text) else -1) or
				binder_card.subtypes.has(CardHelper.SubType.get(search_text) if CardHelper.SubType.has(search_text) else -1) or
				binder_card.talents.has(CardHelper.Talent.get(search_text) if CardHelper.Talent.has(search_text) else -1)
			)
		)

	# Sort
	var sort_property = ""
	var asc : bool = true
	match current_sort_index:
		0:
			sort_property = "name"
		1:
			sort_property = "power"
		2:
			sort_property = "defense"
		3:
			sort_property = "pitch"
		4:
			sort_property = "cost"
		5:
			sort_property = "name"
			asc = false
		6:
			sort_property = "power"
			asc = false
		7:
			sort_property = "defense"
			asc = false
		8:
			sort_property = "pitch"
			asc = false
		9:
			sort_property = "cost"
			asc = false

	filtered_binder_card_resources.sort_custom(func(a:CardResource, b:CardResource):
		var a_val = a.get(sort_property)
		var b_val = b.get(sort_property)
		if asc:
			return a_val < b_val
		else:
			return a_val > b_val
	)
	for scene : BinderCard in loaded_binder_card_scenes.values():
		scene.queue_free()
		
	loaded_binder_card_scenes.clear()
	first_visible_index = 0
	update_visible_cards()

	binder_cards_scroll.scroll_vertical = 0
	scrolled.emit(binder_cards_scroll.get_global_rect())
	
func sort_binder_cards(sort_index: int) -> void:
	current_sort_index = sort_index
	update_binder_display()

func search_binder_cards(search_text: String) -> void:
	current_search_text = search_text
	update_binder_display()
