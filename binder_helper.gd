extends Node

var binders : Dictionary[String, BinderResource] = {}

func _ready():
	load_binders()

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

func save_binder(_binder_name) -> void:
	print("save binder")
