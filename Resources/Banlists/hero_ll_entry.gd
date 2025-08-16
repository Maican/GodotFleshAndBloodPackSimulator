extends HBoxContainer

class_name HeroLLEntry

@onready var hero_label: Label = $HeroLabel
@onready var hero_points_text_edit: LineEdit = $HeroPointsTextEdit

var hero_name : String = ""
var hero_points : int = 0

func _ready() -> void:
	hero_label.text = hero_name
	hero_points_text_edit.text = str(hero_points)

func set_hero_label(text : String) -> void:
	hero_name = text
	if hero_label != null:
		hero_label.text = hero_name
	
func set_hero_points(points : int) -> void:
	hero_points = points
	if hero_points_text_edit != null:
		hero_points_text_edit.text = str(hero_points)

func get_hero_points() -> int:
	if hero_points_text_edit.text != "":
		return hero_points_text_edit.text.to_int()
	else:
		return 0
