extends Control
@onready var grid_container: GridContainer = $Panel/ScrollContainer/GridContainer
@onready var open_pack_button: Button = $Panel/OpenPackButton
const SET_RADIO_BUTTON_GROUP = preload("res://Resources/SetRadioButtonGroup.tres")
const SET_PANEL = preload("res://Sets/set_panel.tscn")
@onready var spin_box: SpinBox = $Panel/SpinBox
const PACK_OPEN_SCREEN = preload("res://pack_open_screen.tscn")
var clicked_pack_resource : PackResource
func _ready() -> void:
	open_pack_button.disabled = true
	open_pack_button.pressed.connect(open_packs)
	for booster_box_name : String in PackOpenHelper.Sets.keys():
		var new_set_panel : SetPanel = SET_PANEL.instantiate()
		grid_container.add_child(new_set_panel)
		new_set_panel.check_box.button_group = SET_RADIO_BUTTON_GROUP
		new_set_panel.check_box.pressed.connect(checkbox_pressed)
		new_set_panel.set_checkbox_name(booster_box_name)

func open_packs() -> void:
	while ( ResourceLoader.load_threaded_get_status("res://PackResources/" + SET_RADIO_BUTTON_GROUP.get_pressed_button().name + ".res") != ResourceLoader.THREAD_LOAD_LOADED ):
		await get_tree().create_timer(0.1).timeout
	PackOpenHelper.opening_pack_resource = ResourceLoader.load_threaded_get("res://PackResources/" + SET_RADIO_BUTTON_GROUP.get_pressed_button().name + ".res")
	PackOpenHelper.packs_to_open = int(spin_box.value)
	get_tree().change_scene_to_packed(PACK_OPEN_SCREEN)

func checkbox_pressed() -> void:
	ResourceLoader.load_threaded_request("res://PackResources/" + SET_RADIO_BUTTON_GROUP.get_pressed_button().name + ".res", "", true)
	open_pack_button.disabled = false

func _on_main_menu_button_pressed() -> void:
	SceneChanger.switch_to_main_menu_scene()
