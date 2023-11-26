extends CanvasLayer
#################################################
# LOADING SCENE
#################################################
var current_scene: Object
var is_in_main: bool = true
var is_loading: bool = false
var is_quit_open: bool = false
var loader: ResourceInteractiveLoader
var scene_path: String
var time_max: int = 100
var wait_frames: int = 0


func _ready() -> void:
	var the_root: Object = get_tree().get_root()
	current_scene = the_root.get_child(the_root.get_child_count() -1)
	set_process_input(true)


func _process(_time: float) -> void:
	if loader == null:
		set_process(false)
		return

	if wait_frames > 0:
		wait_frames -= 1
		return

	var ticks: float = OS.get_ticks_msec()
	while OS.get_ticks_msec() < ticks + time_max:
		var this_status: int = loader.poll()
		if this_status == ERR_FILE_EOF:
			loading_finished(this_status)
			break
		elif this_status == OK:
			update_progress()
		else:
			print("Loading next scene failed, stop game: %s" % this_status)
			loader = null
			break


func loading_finished(this_status: int) -> void:
	print("Loading complete, switch scenes: %s" % this_status)
	var this_resource: Object = loader.get_resource()
	loader = null
	set_new_scene(this_resource)


#################################################
# SCENE LOADING
#################################################
func load_scene(this_path: String) -> void:
	if is_loading == false:
		is_loading = true
		call_deferred("load_scene_deferred", this_path)
	else:
		print("Loading %s example was called again while already loading it" % this_path)


func load_scene_deferred(this_path: String) -> void:
	if this_path == "main":
		is_in_main = true
		scene_path = "res://src/main.tscn"
	else:
		is_in_main = false
		scene_path = "res://src/examples/%s.tscn" % this_path
	loader = ResourceLoader.load_interactive(scene_path)

	if loader == null:
		print("Scene to load is null")
		return
	$Animator.play("Preload")


func set_new_scene(scene: Object) -> void:
	print("Attempting to load: %s" % scene)
	current_scene.free()
	current_scene = scene.instance()
	get_node("/root").add_child(current_scene)
	get_tree().set_current_scene(current_scene)
	$Animator.play("Postload")
	is_loading = false


func update_progress() -> void:
	var animation_progress: float = (float(loader.get_stage()) / loader.get_stage_count())
	var animation_length: float = $Animator.get_current_animation_length()
	$Animator.seek(animation_progress * animation_length, true)


#################################################
# QUIT CONFIRMATION FUNCTIONS
#################################################
func _on_quit_pressed() -> void:
	$Animator.play("Quit Hide")
	get_tree().quit()


func _on_resume_pressed() -> void:
	$Animator.play("Quit Hide")


func show_quit_confirm() -> void:
	is_quit_open = true
	$Animator.play("Quit Show")


##################################################
# ANIMATION FUNCTIONS
##################################################
func _on_animator_finished(this_animation: String) -> void:
	match this_animation:
		"Preload":
			set_process(true)
			$Animator.play("Loading")
			wait_frames = 1
		"Quit Show": is_quit_open = true
		"Quit Hide": is_quit_open = false


##################################################
# INPUT HANDLING
##################################################
func _input(this_event: InputEvent) -> void:
	if this_event.is_pressed() and not this_event.is_echo():
		if this_event.is_action("ui_cancel"):
			if is_quit_open:
				_on_resume_pressed()
			else:
				show_quit_confirm()
