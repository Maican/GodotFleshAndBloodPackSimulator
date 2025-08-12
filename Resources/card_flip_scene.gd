extends TextureButton

class_name CardFlipScene

signal card_hovered
signal card_unhovered
signal card_flipped

var card_resource : CardResource
var is_flipped : bool = false
var is_flipping : bool = false
var next_texture : CompressedTexture2D
@onready var back_texture : CompressedTexture2D = texture_normal
@onready var rarity_texture_rect: TextureRect = $TextureRect
const COMMON = "res://Resources/Images/Rarities/common.png"
const FABLED = "res://Resources/Images/Rarities/fabled.png"
const LEGENDARY = "res://Resources/Images/Rarities/legendary.png"
const MAJESTIC = "res://Resources/Images/Rarities/majestic.png"
const MARVEL = "res://Resources/Images/Rarities/marvel.png"
const RARE = "res://Resources/Images/Rarities/rare.png"
const SUPER_RARE = "res://Resources/Images/Rarities/SuperRare.png"
const TOKEN = "res://Resources/Images/Rarities/token.png"

func _ready() -> void:
	pressed.connect(flip_card)
	mouse_entered.connect(emit_card_hovered)
	mouse_exited.connect(emit_card_unhovered)
	if card_resource != null:
		next_texture = card_resource.load_texture()
		if !card_resource.flip_image_path.is_empty():
			texture_normal = card_resource.load_flip_texture()

func emit_card_hovered() -> void:
	if is_flipped:
		card_hovered.emit(card_resource)

func emit_card_unhovered() -> void:
	if is_flipped:
		card_unhovered.emit(card_resource)

func flip_card(flip_time : float = 0.30) -> void:
	if !is_flipped and !is_flipping:
		is_flipping = true
		var original_size_x : float = get_rect().size.x
		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(self, "scale", Vector2(0.0, 1), flip_time / 2)
		tween.tween_property(self, "position", position + Vector2(original_size_x / 2, 0), flip_time / 2)
		await tween.finished
		var new_tween = create_tween()
		new_tween.set_parallel(true)
		texture_normal = next_texture
		rarity_texture_rect.texture = get_rarity_texture()
		rarity_texture_rect.show()
		new_tween.tween_property(self, "scale", Vector2(1, 1), flip_time / 2)
		new_tween.tween_property(self, "position", position - Vector2(original_size_x / 2, 0), flip_time / 2)
		is_flipped = true
		is_flipping = false
		card_flipped.emit(card_resource)

func get_rarity_texture() -> Texture2D:
	var path : String = COMMON
	match card_resource.rarity:
		CardHelper.Rarity.Token:
			path = TOKEN
		CardHelper.Rarity.Rare:
			path = RARE
		CardHelper.Rarity.Super_Rare:
			path = SUPER_RARE
		CardHelper.Rarity.Majestic:
			path = MAJESTIC
		CardHelper.Rarity.Legendary:
			path = LEGENDARY
		CardHelper.Rarity.Marvel:
			path = MARVEL
		CardHelper.Rarity.Fabled:
			path = FABLED
	return ResourceLoader.load(path, ".png")
