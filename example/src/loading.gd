extends CanvasLayer
#################################################
# LOADING SCENE
#################################################

var is_in_main: bool = true
var is_loading: bool = false
var is_quit_open: bool = false
var progress_completion: Array = []
var scene_path: String

@onready var animator: AnimationPlayer = $Animator

signal load_scene(scene_name : String)


func _ready() -> void:
	set_process_input(true)
	load_scene.connect(_load_scene)


func _process(_delta: float) -> void:
	if is_loading:
		# Check the loading status
		var loading_status: int = ResourceLoader.load_threaded_get_status(scene_path, progress_completion)
		match loading_status:
			ResourceLoader.THREAD_LOAD_IN_PROGRESS:
				_update_animation_progress()
			ResourceLoader.THREAD_LOAD_LOADED:
				_set_new_scene(loading_status)
			ResourceLoader.THREAD_LOAD_FAILED:
				print("[LOADER] Loading next scene failed, stop game: "+str(loading_status))
				is_loading = false


#################################################
# SCENE LOADING
#################################################

func _deferred_load_scene(path: String) -> void:
	if path == "main":
		is_in_main = true
		scene_path = "res://src/main.tscn"
	else:
		is_in_main = false
		scene_path = "res://src/examples/" + str(path) + ".tscn"
	ResourceLoader.load_threaded_request(scene_path)
	print("Starting preload animation")
	animator.play("Preload")


func _load_scene(path: String) -> void:
	if not is_loading:
		is_loading = true
		call_deferred("_deferred_load_scene", path)
	else:
		print(str(path)+" example was called while a scene is already loading")


func _set_new_scene(this_status: int) -> void:
	print("Loading complete, switch scenes: "+str(this_status))
	get_tree().change_scene_to_packed(ResourceLoader.load_threaded_get(scene_path))
	print("Playing postload animation")
	animator.play("Postload")
	is_quit_open = false
	is_loading = false


#################################################
# QUIT CONFIRMATION FUNCTIONS
#################################################
func _show_quit_confirm() -> void:
	is_quit_open = true
	animator.play("Quit Show")


func _on_resume_pressed() -> void:
	animator.play("Quit Hide")


func _on_quit_pressed() -> void:
	animator.play("Quit Hide")
	get_tree().quit()


##################################################
# ANIMATION FUNCTIONS
##################################################
func _on_animator_finished(anim_name: StringName) -> void:
	print("Animation finished: "+str(anim_name))
	match anim_name:
		"Preload":
			set_process(true)
			animator.play("Loading")
		"Quit Show": is_quit_open = true
		"Quit Hide": is_quit_open = false


func _update_animation_progress() -> void:
	var anim_length: float = animator.get_current_animation_length()
	animator.seek(progress_completion[0] * anim_length, true)


##################################################
# INPUT HANDLING
##################################################
func _input(event: InputEvent) -> void:
	if event.is_pressed() and !event.is_echo():
		if event.is_action("ui_cancel"):
			if is_quit_open:
				_on_resume_pressed()
			else:
				_show_quit_confirm()
