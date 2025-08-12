extends Node

const SELECT_PACKS_SCENE = preload("res://select_packs_screen.tscn")
const DECK_EDITOR_SCENE = preload("res://DeckEditor/deck_editor.tscn")
const MAIN_MENU_SCENE = preload("res://main_menu.tscn")
const BANLIST_EDITOR = preload("res://banlist_editor.tscn")
const BINDER_EDITOR = preload("res://binder_editor.tscn")

func switch_to_open_pack_scene() -> void:
	get_tree().change_scene_to_packed(SELECT_PACKS_SCENE)

func switch_to_deck_editor_scene() -> void:
	get_tree().change_scene_to_packed(DECK_EDITOR_SCENE)
	
func switch_to_main_menu_scene() -> void:
	get_tree().change_scene_to_packed(MAIN_MENU_SCENE)

func switch_to_binder_editor_scene() -> void:
	get_tree().change_scene_to_packed(BINDER_EDITOR)
	
func switch_to_banlist_editor_scene() -> void:
	get_tree().change_scene_to_packed(BANLIST_EDITOR)
