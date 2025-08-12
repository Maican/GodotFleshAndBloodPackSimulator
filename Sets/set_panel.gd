extends TextureRect

class_name SetPanel
@onready var check_box: CheckBox = $CheckBox
var pack_resource : PackResource

func set_checkbox_name(box_name : String):
	check_box.text = box_name
	check_box.name = box_name
