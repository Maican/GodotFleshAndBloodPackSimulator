extends Panel

class_name FilterPanel

signal filters_changed
@onready var class_grid_container: GridContainer = $ScrollContainer/VBoxContainer/ClassGridContainer
@onready var rarity_grid_container: GridContainer = $ScrollContainer/VBoxContainer/RarityGridContainer
@onready var type_grid_container: GridContainer = $ScrollContainer/VBoxContainer/TypeGridContainer
@onready var hero_grid_container: GridContainer = $ScrollContainer/VBoxContainer/HeroGridContainer
@onready var talent_grid_container: GridContainer = $ScrollContainer/VBoxContainer/TalentGridContainer
@onready var sub_type_grid_container: GridContainer = $ScrollContainer/VBoxContainer/SubTypeGridContainer
@onready var keyword_grid_container: GridContainer = $ScrollContainer/VBoxContainer/KeywordGridContainer

@onready var pitch_spin_box: SpinBox = $ScrollContainer/VBoxContainer/SpinBoxGridContainer/PitchSpinBox
@onready var cost_spin_box: SpinBox = $ScrollContainer/VBoxContainer/SpinBoxGridContainer/CostSpinBox
@onready var defense_spin_box: SpinBox = $ScrollContainer/VBoxContainer/SpinBoxGridContainer/DefenseSpinBox
@onready var power_spin_box: SpinBox = $ScrollContainer/VBoxContainer/SpinBoxGridContainer/PowerSpinBox
@onready var life_spin_box: SpinBox = $ScrollContainer/VBoxContainer/SpinBoxGridContainer/LifeSpinBox
@onready var intellect_spin_box: SpinBox = $ScrollContainer/VBoxContainer/SpinBoxGridContainer/IntellectSpinBox

@onready var clear_filters_button: Button = $ClearFiltersButton
@onready var set_filters_button: Button = $SetFiltersButton

var current_filters := {
	"classes": [CardHelper.Class,[]],
	"rarities": [CardHelper.Rarity,[]],
	"types": [CardHelper.Type,[]],
	"subtypes": [CardHelper.SubType,[]],
	"hero": [CardHelper.Hero,[]],
	"talents" : [CardHelper.Talent,[]],
	"keywords": [CardHelper.Keyword,[]]
}

var current_numerical_filters := {
	"power": -1,
	"defense": -1,
	"pitch": -1,
	"cost": -1,
	"life": -1,
	"intellect" : -1
}
func _ready() -> void:
	fill_filter_panel()
	# Connect SpinBoxes
	pitch_spin_box.value_changed.connect(set_numerical_filter.bind("pitch"))
	cost_spin_box.value_changed.connect(set_numerical_filter.bind("cost"))
	defense_spin_box.value_changed.connect(set_numerical_filter.bind("defense"))
	power_spin_box.value_changed.connect(set_numerical_filter.bind("power"))
	life_spin_box.value_changed.connect(set_numerical_filter.bind("life"))
	intellect_spin_box.value_changed.connect(set_numerical_filter.bind("intellect"))
	set_filters_button.pressed.connect(func(): filters_changed.emit())
	clear_filters_button.pressed.connect(clear_filters)
	
func set_filter(is_pressed:bool, filter_name : String, value:int) -> void:
	var field = current_filters[filter_name][0]
	if is_pressed:
		current_filters[filter_name][1].append(value)
	else:
		if current_filters[filter_name][1].has(value):
			current_filters[filter_name][1].erase(value)

func set_numerical_filter(value:int, filter_name:String) -> void:
	current_numerical_filters[filter_name] = value

func clear_filters() -> void:
	for checkbox : CheckBox in class_grid_container.get_children():
		checkbox.button_pressed = false
	for checkbox : CheckBox in rarity_grid_container.get_children():
		checkbox.button_pressed = false
	for checkbox : CheckBox in type_grid_container.get_children():
		checkbox.button_pressed = false
	for checkbox : CheckBox in sub_type_grid_container.get_children():
		checkbox.button_pressed = false
	for checkbox : CheckBox in hero_grid_container.get_children():
		checkbox.button_pressed = false
	for checkbox : CheckBox in talent_grid_container.get_children():
		checkbox.button_pressed = false
	for checkbox : CheckBox in keyword_grid_container.get_children():
		checkbox.button_pressed = false
	cost_spin_box.value = -1
	power_spin_box.value = -1
	defense_spin_box.value = -1
	pitch_spin_box.value = -1
	intellect_spin_box.value = -1
	life_spin_box.value = -1
	filters_changed.emit()

func fill_filter_panel() -> void:
	# Add options
	for c in CardHelper.Class.values():
		var checkbox : CheckBox = CheckBox.new()
		checkbox.text = CardHelper.Class.keys()[c]
		checkbox.toggled.connect(set_filter.bind("classes", CardHelper.Class.get(checkbox.text)))
		class_grid_container.add_child(checkbox)
	for r in CardHelper.Rarity.values():
		var checkbox : CheckBox = CheckBox.new()
		checkbox.text = CardHelper.Rarity.keys()[r]
		checkbox.toggled.connect(set_filter.bind("rarities", CardHelper.Rarity.get(checkbox.text)))
		rarity_grid_container.add_child(checkbox)
	for t in CardHelper.Type.values():
		var checkbox : CheckBox = CheckBox.new()
		checkbox.text = CardHelper.Type.keys()[t]
		checkbox.toggled.connect(set_filter.bind("types", CardHelper.Type.get(checkbox.text)))
		type_grid_container.add_child(checkbox)
	for t in CardHelper.SubType.values():
		var checkbox : CheckBox = CheckBox.new()
		checkbox.text = CardHelper.SubType.keys()[t]
		checkbox.toggled.connect(set_filter.bind("subtypes", CardHelper.SubType.get(checkbox.text)))
		sub_type_grid_container.add_child(checkbox)
	for h in CardHelper.Hero.values():
		var checkbox : CheckBox = CheckBox.new()
		checkbox.text = CardHelper.Hero.keys()[h]
		checkbox.toggled.connect(set_filter.bind("heroes", CardHelper.Hero.get(checkbox.text)))
		hero_grid_container.add_child(checkbox)
	for ta in CardHelper.Talent.values():
		var checkbox : CheckBox = CheckBox.new()
		checkbox.text = CardHelper.Talent.keys()[ta]
		checkbox.toggled.connect(set_filter.bind("talents", CardHelper.Talent.get(checkbox.text)))
		talent_grid_container.add_child(checkbox)
	for k in CardHelper.Keyword.values():
		var checkbox : CheckBox = CheckBox.new()
		checkbox.text = CardHelper.Keyword.keys()[k]
		checkbox.toggled.connect(set_filter.bind("keywords", CardHelper.Keyword.get(checkbox.text)))
		keyword_grid_container.add_child(checkbox)

func get_spinbox_filter_map() -> Dictionary:
	var numerical_filter_map = {
		"power": [power_spin_box, "power"],
		"defense": [defense_spin_box, "defense"],
		"pitch": [pitch_spin_box, "pitch"],
		"cost": [cost_spin_box, "cost"],
		"life": [life_spin_box, "life"],
		"intellect": [intellect_spin_box, "intellect"]
	}
	return numerical_filter_map
