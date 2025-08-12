extends Node

var binders : Dictionary[String, BinderResource] = {}
const BINDER_FOLDER : String = "user://BinderResources/"
const MEGA_BINDER_LOCATION : String = BINDER_FOLDER + "all_cards.res"

func _ready():
	load_binders()
	var thread : Thread = Thread.new()
	thread.start(create_mega_binder)
	thread.wait_to_finish()

func load_binders() -> void:
	var dir = DirAccess.open("user://")
	if !dir.file_exists("user://BinderResources"):
		dir.make_dir("user://BinderResources")
	dir.change_dir("user://BinderResources")
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if file_name.ends_with(".res"):
			var binder_path = "user://BinderResources/" + file_name
			var time_before : int = Time.get_ticks_msec()
			var binder = ResourceLoader.load(binder_path)
			var time_after : int = Time.get_ticks_msec()
			print("loading binders took " + str(time_after - time_before))
			if binder != null and binder.resource_name != "":
				binders[binder.resource_name] = binder
		file_name = dir.get_next()
	dir.list_dir_end()

func create_mega_binder() -> void:
	var binder_dir := DirAccess.open(BINDER_FOLDER)
	if !binder_dir.file_exists(MEGA_BINDER_LOCATION):
		var mega_binder : BinderResource = BinderResource.new()
		mega_binder.resource_path = MEGA_BINDER_LOCATION
		mega_binder.resource_name = "all_cards"
		var card_paths : Array[String] = get_all_res_files("res://CardResources")
		var ticks_before : int = Time.get_ticks_msec()
		for card_path : String in card_paths:
			var card_resource : CardResource = ResourceLoader.load(card_path)
			mega_binder.cards.set(card_resource.id, [1, card_resource])
		var ticks_After : int = Time.get_ticks_msec()
		print("creating mega binder took " + str(ticks_After - ticks_before))
		ResourceSaver.save(mega_binder, MEGA_BINDER_LOCATION)
		binders[mega_binder.resource_name] = mega_binder

func get_all_res_files(path: String) -> Array[String]:
	var results: Array[String] = []
	var dir := DirAccess.open(path)
	
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if dir.current_is_dir():
				if file_name != "." and file_name != "..":
					results += get_all_res_files(path.path_join(file_name))
			else:
				if file_name.ends_with(".res"):
					results.append(path.path_join(file_name))
			file_name = dir.get_next()
		dir.list_dir_end()
	else:
		push_error("Cannot open directory: " + path)
	
	return results

func save_binder(_binder_name) -> void:
	print("save binder")
