extends TextureRect

class_name SetPanel
@onready var check_box: CheckBox = $CheckBox
@onready var card_count_label: Label = $CardCountLabel
@onready var pack_size_label: Label = $PackSizeLabel
@onready var release_date_label: Label = $ReleaseDateLabel
var pack_resource : PackResource

func setup(box_name : String, resource : PackResource) -> void:
	check_box.text = box_name
	check_box.name = box_name
	pack_resource = resource
	if pack_resource:
		card_count_label.text = str(pack_resource.number_of_cards) + " cards"
		pack_size_label.text = str(pack_resource.pack_size) + " per pack"
		release_date_label.text = pack_resource.release_date
	else:
		card_count_label.text = ""
		pack_size_label.text = ""
		release_date_label.text = ""
