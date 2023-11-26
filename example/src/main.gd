extends Panel
#################################################
# MAIN MENU SCENE
#################################################
func handle_url_failure(this_call_response: int, this_url: String) -> void:
	if this_call_response != OK:
		push_warning("[WARNING] Failed to open %s URL" % this_url)


func _on_exit_pressed() -> void:
	get_tree().quit()


func _on_open_url_pressed(this_url: String) -> void:
	match this_url:
		"discord":
			handle_url_failure(OS.shell_open("https://discord.gg/SJRSq6K"), "Discord")
		"docs":
			handle_url_failure(OS.shell_open("https://godotsteam.com"), "GodotSteam Docs")
		"email":
			handle_url_failure(OS.shell_open("mailto:support@godotsteam.com"), "Email")
		"examples":
			handle_url_failure(OS.shell_open("https://github.com/CoaguCo-Industries/GodotSteam-Examples"), "GodotSteam Examples Github")
		"github":
			handle_url_failure(OS.shell_open("https://github.com/CoaguCo-Industries/GodotSteam"), "GodotSteam Github")
		"steam":
			handle_url_failure(OS.shell_open("https://partner.steamgames.com/doc/sdk"), "Steamworks SDK")


func start_example(which: String) -> void:
	print("Loading up %s example" % which)
	Loading.load_scene(which)
