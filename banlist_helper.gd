extends Node

var banlists : Dictionary[String, BanlistResource] = {}

func _ready():
	var thread : Thread = Thread.new()
	thread.start(load_banlists)
	thread.wait_to_finish()

func load_banlists() -> void:
	var dir = DirAccess.open("user://")
	if !dir.file_exists("user://BanlistResources"):
		dir.make_dir("user://BanlistResources")
	dir.change_dir("user://BanlistResources")
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if file_name.ends_with(".res"):
			var banlist_path = "user://BanlistResources/" + file_name
			var banlist = ResourceLoader.load(banlist_path)
			if banlist != null and banlist.resource_name != "":
				banlists[banlist.resource_name] = banlist
		file_name = dir.get_next()
	dir.list_dir_end()
