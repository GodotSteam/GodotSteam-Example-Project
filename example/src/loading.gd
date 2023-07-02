extends CanvasLayer
#################################################
# LOADING SCENE
#################################################
var CURRENT_SCENE: Object
var IS_IN_MAIN: bool = true
var IS_LOADING: bool = false
var IS_QUIT_OPEN: bool = false
var LOADER: ResourceLoader
var PROGRESS: Array = []
var SCENE_PATH: String
var TIME_MAX: int = 100
var WAIT_FRAMES: int = 0


func _ready() -> void:
	set_process_input(true)


func _process(_delta: float) -> void:
	if IS_LOADING:
		# Check the loading status
		var LOADING_STATUS: int = ResourceLoader.load_threaded_get_status(SCENE_PATH, PROGRESS)
		match LOADING_STATUS:
			ResourceLoader.THREAD_LOAD_IN_PROGRESS:
				_update_Progress()
			ResourceLoader.THREAD_LOAD_LOADED:
				_set_New_Scene(LOADING_STATUS)
			ResourceLoader.THREAD_LOAD_FAILED:
				print("[LOADER] Loading next scene failed, stop game: "+str(LOADING_STATUS))
				IS_LOADING = false


#################################################
# SCENE LOADING
#################################################
func _deferred_Load_Scene(path: String) -> void:
	if path == "main":
		IS_IN_MAIN = true
		SCENE_PATH = "res://src/main.tscn"
	else:
		IS_IN_MAIN = false
		SCENE_PATH = "res://src/examples/"+str(path)+".tscn"
	ResourceLoader.load_threaded_request(SCENE_PATH)
	print("Starting preload animation")
	$Animator.play("Preload")


func _load_Scene(path: String) -> void:
	if IS_LOADING == false:
		IS_LOADING = true
		call_deferred("_deferred_Load_Scene", path)
	else:
		print(str(path)+" example was called while a scene is already loading")


func _set_New_Scene(this_status: int) -> void:
	print("Loading complete, switch scenes: "+str(this_status))
	get_tree().change_scene_to_packed(ResourceLoader.load_threaded_get(SCENE_PATH))
	print("Playing postload animation")
	$Animator.play("Postload")
	IS_LOADING = false


func _update_Progress() -> void:
	var LENGTH: float = $Animator.get_current_animation_length()
	$Animator.seek(PROGRESS[0] * LENGTH, true)


#################################################
# QUIT CONFIRMATION FUNCTIONS
#################################################
func _show_Quit_Confirm() -> void:
	IS_QUIT_OPEN = true
	$Animator.play("Quit Show")


func _on_Resume_pressed() -> void:
	$Animator.play("Quit Hide")


func _on_Quit_pressed() -> void:
	$Animator.play("Quit Hide")
	get_tree().quit()


##################################################
# ANIMATION FUNCTIONS
##################################################
func _on_Animator_Finished(this_animation: String) -> void:
	print("Animation finished: "+str(this_animation))
	match this_animation:
		"Preload":
			set_process(true)
			$Animator.play("Loading")
		"Quit Show": IS_QUIT_OPEN = true
		"Quit Hide": IS_QUIT_OPEN = false


##################################################
# INPUT HANDLING
##################################################
func _input(event: InputEvent) -> void:
	if event.is_pressed() and !event.is_echo():
		if event.is_action("ui_cancel"):
			if IS_QUIT_OPEN:
				_on_Resume_pressed()
			else:
				_show_Quit_Confirm()
