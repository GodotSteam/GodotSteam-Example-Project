extends CanvasLayer
#################################################
# LOADING SCENE
#################################################
var CURRENT_SCENE: Object
var IS_IN_MAIN: bool = true
var IS_LOADING: bool = false
var IS_QUIT_OPEN: bool = false
var LOADER: ResourceInteractiveLoader
var SCENE_PATH: String
var TIME_MAX: int = 100
var WAIT_FRAMES: int = 0


func _ready() -> void:
	var ROOT: Object = get_tree().get_root()
	CURRENT_SCENE = ROOT.get_child(ROOT.get_child_count() -1)
	set_process_input(true)


func _process(_time: float) -> void:
	if LOADER == null:
		set_process(false)
		return

	if WAIT_FRAMES > 0:
		WAIT_FRAMES -= 1
		return

	var TICKS: float = OS.get_ticks_msec()
	while OS.get_ticks_msec() < TICKS + TIME_MAX:
		var ERR: int = LOADER.poll()
		if ERR == ERR_FILE_EOF:
			_loading_Finished(ERR)
			break
		elif ERR == OK:
			_update_Progress()
		else:
			print("[LOADER] Loading next scene failed, stop game: "+str(ERR))
			LOADER = null
			break


func _loading_Finished(this_status: int) -> void:
	print("Loading complete, switch scenes: "+str(this_status))
	var RESOURCE: Object = LOADER.get_resource()
	LOADER = null
	_set_New_Scene(RESOURCE)


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
	LOADER = ResourceLoader.load_interactive(SCENE_PATH)

	if LOADER == null:
		print("Scene to load is null")
		return
	$Animator.play("Preload")


func _load_Scene(path: String) -> void:
	if IS_LOADING == false:
		IS_LOADING = true
		call_deferred("_deferred_Load_Scene", path)
	else:
		print("Loading "+str(path)+" example was called again while already loading it")


func _set_New_Scene(scene: Object) -> void:
	print("Attempting to load: "+str(scene))
	CURRENT_SCENE.free()
	CURRENT_SCENE = scene.instance()
	get_node("/root").add_child(CURRENT_SCENE)
	get_tree().set_current_scene(CURRENT_SCENE)
	$Animator.play("Postload")
	IS_LOADING = false


func _update_Progress() -> void:
	var PROGRESS: float = (float(LOADER.get_stage()) / LOADER.get_stage_count())
	var LENGTH: float = $Animator.get_current_animation_length()
	$Animator.seek(PROGRESS * LENGTH, true)


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
	match this_animation:
		"Preload":
			set_process(true)
			$Animator.play("Loading")
			WAIT_FRAMES = 1
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
