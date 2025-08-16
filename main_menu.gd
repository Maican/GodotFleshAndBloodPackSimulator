extends Panel

class_name MainMenu

@onready var open_pack_button: Button = $VBoxContainer2/OpenPackButton
@onready var deck_editor_button: Button = $VBoxContainer2/DeckEditorButton
@onready var binder_editor_button: Button = $VBoxContainer2/BinderEditorButton
@onready var banlist_editor_button: Button = $VBoxContainer2/BanlistEditorButton
@onready var exit_button: Button = $VBoxContainer2/ExitButton

@onready var json_importer: JsonImporter = $JSONImporter
@onready var dev_menu_button: MenuButton = $DevMenuButton

@onready var importing_card_label: Label = $VBoxContainer/ImportingCardLabel
@onready var importing_card: Label = $VBoxContainer/ImportingCardNumber
var image_queue_ids : Array[String] = []
var image_queue : Array[CardResource] = []
var active_requests : int = 0
var cards_downloaded : int = 0
var total_cards : int = 0
const MAX_CONCURRENT_REQUESTS : int = 40
var import_started : bool = false
var import_finished : bool = false
var download_started : bool = false
var download_finished : bool = false

func _ready() -> void:
	randomize()
	open_pack_button.pressed.connect(switch_to_open_pack_scene)
	deck_editor_button.pressed.connect(switch_to_deck_editor_scene)
	binder_editor_button.pressed.connect(switch_to_binder_editor_scene)
	banlist_editor_button.pressed.connect(switch_to_banlist_editor_scene)
	exit_button.pressed.connect(exit)
	dev_menu_button.get_popup().id_pressed.connect(dev_menu_button_pressed)
	json_importer.import_started.connect(func(): 
		import_started = true
		importing_card_label.show()
		importing_card.show()
		importing_card_label.text = "Importing cards from JSON"
	)
	json_importer.download_started.connect(func(): 
		download_started = true
		importing_card_label.text = "Downloading cards from WEB"
	)
	json_importer.progress_string_changed.connect(func():
		importing_card.text = json_importer.progress_string
	)
	json_importer.download_finished.connect(func():
		importing_card.text = "Finished!"
		)
		
func switch_to_open_pack_scene() -> void:
	SceneChanger.switch_to_open_pack_scene()

func switch_to_deck_editor_scene() -> void:
	SceneChanger.switch_to_deck_editor_scene()

func switch_to_banlist_editor_scene() -> void:
	SceneChanger.switch_to_banlist_editor_scene()

func switch_to_binder_editor_scene() -> void:
	SceneChanger.switch_to_binder_editor_scene()
	
func exit() -> void:
	get_tree().quit()

func disable_buttons(disabled : bool) -> void:
	open_pack_button.disabled = disabled
	deck_editor_button.disabled = disabled
	exit_button.disabled = disabled
	importing_card_label.visible = disabled
	importing_card.visible = disabled

func clear_cards_and_packs() -> void:
	var dir_access := DirAccess.open("res://PackResources")
	
	for file in dir_access.get_files():
		if file.ends_with(".res"):
			var pack_resource : PackResource = ResourceLoader.load("res://PackResources//" + file)
			pack_resource.clear_cards()
			ResourceSaver.save(pack_resource, pack_resource.resource_path)

func dev_menu_button_pressed(item_id : int) -> void:
	if item_id == 0:
		clear_cards_and_packs()
	elif item_id == 1:
		json_importer.import_cards()
	elif item_id == 2:
		OS.shell_show_in_file_manager(ProjectSettings.globalize_path("user://"))
