extends TextureRect

class_name CardHoverPanel

@onready var flip_texture_rect: TextureRect = $FlipTextureRect

const flip_card_left_pos : Vector2 = Vector2(-308,0)
const flip_card_right_pos : Vector2 = Vector2(375, 0)

func _process(_delta: float) -> void:
	var mouse_pos = get_global_mouse_position()
	var viewport_size = get_viewport_rect().size

	# Default: show to the right and below the mouse
	var pos = mouse_pos

	# If panel would go off right edge, show to the left of mouse
	if pos.x + size.x > viewport_size.x:
		pos.x = mouse_pos.x - size.x - 100
	else:
		pos.x = mouse_pos.x + 100
	# If panel would go off bottom edge, show above mouse
	if pos.y + size.y > viewport_size.y:
		pos.y = mouse_pos.y - size.y - 5
	else:
		pos.y = mouse_pos.y + 5

	# Clamp to top/left edges
	pos.x = clamp(pos.x, 0, viewport_size.x - size.x)
	pos.y = clamp(pos.y, 0, viewport_size.y - size.y)
	
	global_position = pos

func set_card_resource(card_resource : CardResource) -> void:
	texture = card_resource.load_texture()
	flip_texture_rect.hide()
	if card_resource.flip_image_path:
		flip_texture_rect.texture = card_resource.load_flip_texture()
		flip_texture_rect.show()
