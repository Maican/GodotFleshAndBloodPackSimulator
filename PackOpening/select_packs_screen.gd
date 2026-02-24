extends Control
@onready var grid_container: GridContainer = $Panel/ScrollContainer/GridContainer
@onready var open_pack_button: Button = $Panel/OpenPackButton
const SET_RADIO_BUTTON_GROUP = preload("res://Resources/SetRadioButtonGroup.tres")
const SET_PANEL = preload("res://Sets/set_panel.tscn")
@onready var spin_box: SpinBox = $Panel/SpinBox
const PACK_OPEN_SCREEN = preload("res://PackOpening/pack_open_screen.tscn")
var clicked_pack_resource : PackResource
func _ready() -> void:
	open_pack_button.disabled = true
	open_pack_button.pressed.connect(open_packs)
	for booster_box_name : String in PackOpenHelper.Sets.keys():
		var pack_path : String = "res://PackResources/" + booster_box_name + ".res"
		var pack_res : PackResource = null
		if FileAccess.file_exists(pack_path):
			pack_res = ResourceLoader.load(pack_path)
		var new_set_panel : SetPanel = SET_PANEL.instantiate()
		grid_container.add_child(new_set_panel)
		new_set_panel.check_box.button_group = SET_RADIO_BUTTON_GROUP
		new_set_panel.check_box.pressed.connect(checkbox_pressed)
		new_set_panel.setup(booster_box_name, pack_res)

func open_packs() -> void:
	var selected_panel : SetPanel = _get_selected_set_panel()
	if selected_panel == null or selected_panel.pack_resource == null:
		return
	PackOpenHelper.opening_pack_resource = selected_panel.pack_resource
	PackOpenHelper.packs_to_open = int(spin_box.value)
	PackOpenHelper.opened_cards.clear()
	get_tree().change_scene_to_packed(PACK_OPEN_SCREEN)

func checkbox_pressed() -> void:
	if SET_RADIO_BUTTON_GROUP.get_pressed_button():
		open_pack_button.disabled = false

func _get_selected_set_panel() -> SetPanel:
	var pressed_button := SET_RADIO_BUTTON_GROUP.get_pressed_button()
	if pressed_button == null:
		return null
	for child in grid_container.get_children():
		if child is SetPanel and child.check_box == pressed_button:
			return child
	return null

func _on_main_menu_button_pressed() -> void:
	SceneChanger.switch_to_main_menu_scene()
